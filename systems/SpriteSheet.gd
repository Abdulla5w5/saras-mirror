class_name SpriteSheet
extends RefCounted
## Helpers for building SpriteFrames from horizontal strip sheets at runtime,
## so we never hand-author AtlasTexture regions in .tres files. Every craftpix
## sheet used here is a single row of square frames.

## Add one animation from a horizontal strip. `count` frames of `frame_w` x sheet
## height, starting at frame `from`. Pass count <= 0 to auto-fill the whole row.
static func add_strip(sf: SpriteFrames, anim: String, tex: Texture2D,
		frame_w: int, count: int = -1, fps: float = 10.0, loop: bool = true,
		from: int = 0) -> void:
	if tex == null:
		return
	var h := tex.get_height()
	var total := int(tex.get_width() / float(frame_w))
	if count <= 0:
		count = total - from
	if not sf.has_animation(anim):
		sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	for i in range(from, from + count):
		if i >= total:
			break
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * frame_w, 0, frame_w, h)
		sf.add_frame(anim, at)

static func load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Missing texture: %s" % path)
	return null
