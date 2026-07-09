class_name Enemy
extends CharacterBody2D
## Configurable nightmare. Idles/patrols until Sara enters aggro range, then
## chases and deals contact damage. Each enemy carries a `speaker` + voice lines
## (aggro/defeat) shown in the Talk box so they can be dubbed later. On death it
## shatters like glass — these are illusions, after all.
##
## Configure the public vars BEFORE adding to the tree, then add_child.

# --- config (set by the level) ---------------------------------------------
var sheet_dir := "res://assets/enemies/vampire_girl/"
var speaker := "The Shade"
var aggro_lines: Array = ["You are still dreaming, little one."]
var defeat_lines: Array = ["...back to the glass I go..."]
var max_hp := 3
var move_speed := 120.0
var aggro_range := 240.0
var give_up_range := 460.0
var contact_damage := 1
var tint := Color(1, 1, 1)
var is_boss := false                       # bigger death payoff (hit-stop)
var patrol_points: Array = []              # optional Vector2 waypoints (world)

# --- state ------------------------------------------------------------------
enum { WANDER, CHASE, HURT, DEAD }
var _state := WANDER
var hp := 3
var facing_left := false
var _home := Vector2.ZERO
var _patrol_i := 0
var _spoke := false
var _hurt_t := 0.0
var _touch_cd := 0.0
var _wander_t := 0.0
var _wander_dir := Vector2.ZERO
var _sprite: AnimatedSprite2D
var _touch: Area2D


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 3
	collision_mask = 1
	hp = max_hp
	_home = global_position
	z_index = 2

	_build_sprite()

	var col := CollisionShape2D.new()
	var cap := CapsuleShape2D.new(); cap.radius = 13.0; cap.height = 28.0
	col.shape = cap
	col.position = Vector2(0, -9)
	add_child(col)

	_touch = Area2D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = 2
	var tc := CollisionShape2D.new()
	var ts := CircleShape2D.new(); ts.radius = 20.0
	tc.shape = ts; tc.position = Vector2(0, -9)
	_touch.add_child(tc)
	add_child(_touch)


func _build_sprite() -> void:
	var sf := SpriteFrames.new()
	SpriteSheet.add_strip(sf, "idle",   SpriteSheet.load_tex(sheet_dir + "Idle.png"), 128, -1, 7.0)
	SpriteSheet.add_strip(sf, "walk",   SpriteSheet.load_tex(sheet_dir + "Walk.png"), 128, -1, 11.0)
	SpriteSheet.add_strip(sf, "hurt",   SpriteSheet.load_tex(sheet_dir + "Hurt.png"), 128, -1, 10.0, false)
	SpriteSheet.add_strip(sf, "dead",   SpriteSheet.load_tex(sheet_dir + "Dead.png"), 128, -1, 12.0, false)
	if not sf.has_animation("idle"):
		sf.add_animation("idle"); sf.add_frame("idle", PlaceholderTexture2D.new())
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = sf
	_sprite.scale = Vector2(0.85, 0.85)
	_sprite.offset = Vector2(0, -52)
	_sprite.modulate = tint
	_sprite.play("idle")
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_touch_cd = maxf(_touch_cd - delta, 0.0)
	if _state == DEAD:
		return
	var player := Game.get_player() as Node2D
	var to_player := INF
	if player:
		to_player = global_position.distance_to(player.global_position)

	match _state:
		HURT:
			_hurt_t -= delta
			velocity = velocity.move_toward(Vector2.ZERO, 900 * delta)
			if _hurt_t <= 0.0:
				_state = CHASE if to_player < give_up_range else WANDER
		WANDER:
			_wander(delta)
			if to_player < aggro_range:
				_enter_chase()
		CHASE:
			if player == null or to_player > give_up_range:
				_state = WANDER
			else:
				var dir := (player.global_position - global_position).normalized()
				velocity = velocity.move_toward(dir * move_speed, 1200 * delta)
				facing_left = dir.x < 0.0
				_play("walk")

	move_and_slide()
	_sprite.flip_h = facing_left
	_contact_damage()


func _wander(delta: float) -> void:
	if not patrol_points.is_empty():
		var target: Vector2 = patrol_points[_patrol_i]
		var dir := (target - global_position)
		if dir.length() < 12.0:
			_patrol_i = (_patrol_i + 1) % patrol_points.size()
		else:
			velocity = velocity.move_toward(dir.normalized() * move_speed * 0.6, 800 * delta)
			facing_left = dir.x < 0.0
			_play("walk")
			return
	# idle drift near home
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(1.2, 2.6)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU) if randf() < 0.6 else Vector2.ZERO
	if _wander_dir != Vector2.ZERO and global_position.distance_to(_home) < 120.0:
		velocity = velocity.move_toward(_wander_dir * move_speed * 0.4, 600 * delta)
		facing_left = _wander_dir.x < 0.0
		_play("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
		_play("idle")


func _enter_chase() -> void:
	_state = CHASE
	if not _spoke:
		_spoke = true
		var line: String = aggro_lines[randi() % aggro_lines.size()] if not aggro_lines.is_empty() else ""
		if line != "":
			Talk.say(speaker, line, Color(1.0, 0.6, 0.6))
			Audio.enemy_speak()


func _contact_damage() -> void:
	if _touch_cd > 0.0:
		return
	for b in _touch.get_overlapping_bodies():
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(contact_damage, global_position)
			_touch_cd = 0.7
			return


func _play(anim: String) -> void:
	if _sprite.animation != anim or not _sprite.is_playing():
		if _sprite.sprite_frames.has_animation(anim):
			_sprite.play(anim)


func take_damage(amount: int, from_pos: Vector2) -> void:
	if _state == DEAD:
		return
	hp -= amount
	Audio.hit()
	FX.burst(global_position + Vector2(0, -20), Color(0.8, 0.85, 1.0), 10, 120.0)
	if hp <= 0:
		_die()
		return
	_state = HURT
	_hurt_t = 0.25
	velocity = (global_position - from_pos).normalized() * 320.0
	_play("hurt")
	_sprite.modulate = Color(1.6, 1.4, 1.4)
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", tint, 0.2)


func _die() -> void:
	_state = DEAD
	collision_layer = 0
	_touch.queue_free()
	_play("dead")
	FX.illusion_break(global_position + Vector2(0, -24), Color(0.7, 0.8, 1.0))
	if is_boss:                                   # climax beat
		FX.hit_pause(0.16, 0.05)
		FX.flash(Color(0.9, 0.95, 1.0), 0.5)
		FX.add_trauma(0.6)
	var line: String = defeat_lines[randi() % defeat_lines.size()] if not defeat_lines.is_empty() else ""
	if line != "":
		Talk.say(speaker, line, Color(0.7, 0.8, 1.0))
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.28))
