class_name Player
extends CharacterBody2D
## Sara — top-down explorer built entirely in code. Slices her craftpix sheets
## into a SpriteFrames, walks in 8 directions (sprite flips L/R, side-facing),
## dashes, does a short mirror-shard strike, and casts True Sight (Q).
##
## Collision layers:  1 world/walls · 2 player · 3 enemy · 4 interactable
## The body collides with world only; enemies/pickups reach Sara through Areas.

signal health_changed(current: int, max: int)
signal died()

const SPEED := 190.0
const ACCEL := 1600.0
const FRICTION := 1900.0
const DASH_SPEED := 560.0
const DASH_TIME := 0.16
const DASH_CD := 0.5
const MAX_HP := 5
const INVULN := 0.8

const SHEET := "res://assets/sara/"

var hp := MAX_HP
var facing_left := false
var speed_mult := 1.0   # set by hazards like Quicksand (enter/exit signals)
var has_ladder := false # picked up a ladder to bridge a quicksand crossing
var _dash_left := 0.0
var _dash_cd := 0.0
var _attacking := false
var _invuln := 0.0
var _step_t := 0.0
var _knockback := Vector2.ZERO

var _sprite: AnimatedSprite2D
var _interactor: Area2D
var _hitbox: Area2D
var _cam: Camera2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

	_build_sprite()

	var col := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 12.0
	cap.height = 26.0
	col.shape = cap
	col.position = Vector2(0, -8)
	add_child(col)

	# Interaction probe (levers, signs, portals) — group "interactable".
	_interactor = Area2D.new()
	_interactor.collision_layer = 0
	_interactor.collision_mask = 4
	var ic := CollisionShape2D.new()
	var ics := CircleShape2D.new(); ics.radius = 46.0
	ic.shape = ics; ic.position = Vector2(0, -8)
	_interactor.add_child(ic)
	add_child(_interactor)

	# Attack hitbox — enabled in bursts, hits enemy bodies (layer 3).
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 3
	_hitbox.monitoring = false
	var hc := CollisionShape2D.new()
	var hcs := RectangleShape2D.new(); hcs.size = Vector2(46, 40)
	hc.shape = hcs
	_hitbox.add_child(hc)
	add_child(_hitbox)

	_cam = Camera2D.new()
	_cam.zoom = Vector2(1.7, 1.7)
	_cam.position_smoothing_enabled = true
	_cam.position_smoothing_speed = 7.0
	add_child(_cam)
	_cam.make_current()

	Game.register_player(self)
	Game.set_checkpoint(global_position)
	health_changed.emit(hp, MAX_HP)


func _build_sprite() -> void:
	var sf := SpriteFrames.new()
	SpriteSheet.add_strip(sf, "idle",    SpriteSheet.load_tex(SHEET + "Idle.png"), 128, 7, 8.0)
	SpriteSheet.add_strip(sf, "walk",    SpriteSheet.load_tex(SHEET + "Walk.png"), 128, 12, 14.0)
	SpriteSheet.add_strip(sf, "attack",  SpriteSheet.load_tex(SHEET + "Attack.png"), 128, 9, 18.0, false)
	SpriteSheet.add_strip(sf, "cast",    SpriteSheet.load_tex(SHEET + "Protection.png"), 128, 2, 8.0)
	if not sf.has_animation("idle"):   # fallback so the game still runs assetless
		sf.add_animation("idle"); sf.add_frame("idle", PlaceholderTexture2D.new())
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.scale = Vector2(0.85, 0.85)
	_sprite.offset = Vector2(0, -52)     # bring feet to the node origin (Y-sort key)
	_sprite.play("idle")
	_sprite.animation_finished.connect(_on_anim_finished)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_invuln = maxf(_invuln - delta, 0.0)

	var input := Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down"))
	if input.length() > 1.0:
		input = input.normalized()

	# Dash
	if _dash_left > 0.0:
		_dash_left -= delta
	elif Input.is_action_just_pressed(&"dash") and _dash_cd <= 0.0 and input != Vector2.ZERO and not _attacking:
		_dash_left = DASH_TIME
		_dash_cd = DASH_CD
		velocity = input * DASH_SPEED
		Audio.dash()
		FX.burst(global_position, Color(0.7, 0.8, 1.0), 8, 60.0)

	# Attack
	if Input.is_action_just_pressed(&"attack") and not _attacking and _dash_left <= 0.0:
		_start_attack()

	# True Sight
	if Input.is_action_just_pressed(&"true_sight"):
		if Illusion.activate(global_position):
			if not _attacking:
				_sprite.play("cast")

	# Interact
	if Input.is_action_just_pressed(&"interact"):
		_try_interact()

	# Movement integration
	if _dash_left > 0.0:
		pass # keep dash velocity
	elif _knockback.length() > 4.0:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	elif input != Vector2.ZERO and not _attacking:
		velocity = velocity.move_toward(input * SPEED * speed_mult, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	if input.x != 0.0:
		facing_left = input.x < 0.0

	move_and_slide()
	_update_anim(input)
	_footsteps(delta, input)
	_apply_camera_shake()


func _update_anim(input: Vector2) -> void:
	_sprite.flip_h = facing_left
	_hitbox.position = Vector2(-40 if facing_left else 40, -8)
	if _attacking or _sprite.animation == "cast" and _sprite.is_playing():
		return
	if velocity.length() > 12.0 and input != Vector2.ZERO:
		if _sprite.animation != "walk":
			_sprite.play("walk")
	else:
		if _sprite.animation != "idle":
			_sprite.play("idle")
	# tint slightly while invulnerable
	_sprite.modulate = Color(1, 0.7, 0.7) if _invuln > 0.0 else Color.WHITE


func _footsteps(delta: float, input: Vector2) -> void:
	if velocity.length() > 40.0 and input != Vector2.ZERO and _dash_left <= 0.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.32
			Audio.step()
	else:
		_step_t = 0.0


func _start_attack() -> void:
	_attacking = true
	_sprite.play("attack")
	Audio.hit()
	_hitbox.monitoring = true
	await get_tree().create_timer(0.14).timeout
	if is_instance_valid(self):
		for b in _hitbox.get_overlapping_bodies():
			if b.is_in_group("enemy") and b.has_method("take_damage"):
				b.take_damage(1, global_position)
				FX.add_trauma(0.15)
		_hitbox.monitoring = false


func _on_anim_finished() -> void:
	if _sprite.animation == "attack":
		_attacking = false
		_sprite.play("idle")
	elif _sprite.animation == "cast":
		_sprite.play("idle")


func _try_interact() -> void:
	var best: Node = null
	var best_d := INF
	for a in _interactor.get_overlapping_areas():
		if a.has_method("interact"):
			var d: float = global_position.distance_to(a.global_position)
			if d < best_d:
				best_d = d; best = a
	if best:
		best.interact()


func _apply_camera_shake() -> void:
	if _cam:
		_cam.offset = FX.get_shake_offset()
		_cam.rotation = FX.get_shake_roll()


func _draw() -> void:
	# soft grounding shadow under the feet (drawn before the child sprite)
	draw_set_transform(Vector2(0, -2), 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.28))
	# carried-ladder indicator above her head
	if has_ladder:
		draw_set_transform(Vector2(0, -96), 0.35, Vector2.ONE)
		var c := Color(0.75, 0.6, 0.35)
		draw_line(Vector2(-14, 0), Vector2(14, 0), c, 3.0)
		draw_line(Vector2(-14, 8), Vector2(14, 8), c, 3.0)
		for rx in [-8, 0, 8]:
			draw_line(Vector2(rx, 0), Vector2(rx, 8), c, 2.0)


# --- Damage / respawn -------------------------------------------------------
func take_damage(amount: int, from_pos: Vector2 = global_position) -> void:
	if _invuln > 0.0 or hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, MAX_HP)
	_invuln = INVULN
	_knockback = (global_position - from_pos).normalized() * 260.0
	Audio.hurt()
	FX.add_trauma(0.35)
	FX.flash(Color(0.8, 0.1, 0.1), 0.2)
	if hp <= 0:
		_die()

func heal(amount: int) -> void:
	hp = mini(hp + amount, MAX_HP)
	health_changed.emit(hp, MAX_HP)

func _die() -> void:
	died.emit()
	Audio.hurt()
	await get_tree().create_timer(0.9).timeout
	if not is_instance_valid(self):
		return
	hp = MAX_HP
	health_changed.emit(hp, MAX_HP)
	_invuln = INVULN
	Game.respawn_player()

func teleport_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO

func apply_slow(factor: float) -> void:
	speed_mult = factor

func give_ladder() -> void:
	has_ladder = true
	queue_redraw()

func use_ladder() -> bool:
	if has_ladder:
		has_ladder = false
		queue_redraw()
		return true
	return false

var _sinking := false

## Called each frame by Quicksand while wading (ratio 0..1 of the 4s sink). At 1
## she goes under and the level restarts.
func set_sink(ratio: float) -> void:
	if _sinking:
		return
	if ratio >= 1.0:
		_drown()
		return
	_sprite.offset.y = -52.0 + ratio * 40.0            # sink into the sand
	_sprite.modulate = Color.WHITE.lerp(Color(0.5, 0.4, 0.25), ratio)

func _drown() -> void:
	_sinking = true
	set_physics_process(false)
	Audio.hurt()
	FX.flash(Color(0.3, 0.2, 0.1), 0.4)
	var tw := create_tween()
	tw.tween_property(_sprite, "offset:y", 20.0, 0.8)
	tw.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.8)
	tw.tween_callback(Game.reload_level)

func set_camera_limits(r: Rect2) -> void:
	if _cam == null:
		return
	_cam.limit_left = int(r.position.x)
	_cam.limit_top = int(r.position.y)
	_cam.limit_right = int(r.position.x + r.size.x)
	_cam.limit_bottom = int(r.position.y + r.size.y)
