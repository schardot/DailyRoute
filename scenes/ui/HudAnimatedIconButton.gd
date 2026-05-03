class_name HudAnimatedIconButton
extends Control

signal interacted

@export var pad_h: float = 8.0
@export var pad_v: float = 8.0

@export var idle_texture: Texture2D:
	set(value):
		idle_texture = value
		if is_node_ready() and idle_rect:
			_apply_idle_texture_to_rect()

@onready var idle_rect: TextureRect = $IdleTexture
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit: Button = $HitArea


func _ready() -> void:
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.button_down.connect(_on_hit_down)
	hit.pressed.connect(_on_hit_pressed)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_idle_texture_to_rect()
	sprite.visible = false
	call_deferred("_fit_size")
	call_deferred("_center_sprite")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_center_sprite()
	elif what == NOTIFICATION_THEME_CHANGED:
		call_deferred("_fit_size")


func _apply_idle_texture_to_rect() -> void:
	if idle_rect == null:
		return
	if idle_texture:
		idle_rect.texture = idle_texture
		idle_rect.visible = true
	else:
		idle_rect.texture = null
		idle_rect.visible = false


func _anim_first_frame_size(sf: SpriteFrames, anim_name: StringName) -> Vector2:
	if sf == null or anim_name.is_empty():
		return Vector2.ZERO
	var t: Texture2D = sf.get_frame_texture(anim_name, 0)
	if t == null:
		return Vector2.ZERO
	return t.get_size()


func _reference_size_for_overlay() -> Vector2:
	return idle_texture.get_size() if idle_texture else Vector2.ZERO


func _apply_overlay_scale(fs: Vector2, ref_sz: Vector2, apply_to: AnimatedSprite2D = null) -> void:
	var node: AnimatedSprite2D = apply_to if apply_to != null else sprite
	var avail := size
	if avail.x <= 0.0 or avail.y <= 0.0:
		return
	var target: Vector2
	if ref_sz.x <= 0.0 or ref_sz.y <= 0.0:
		target = avail
	else:
		target = ref_sz * minf(avail.x / ref_sz.x, avail.y / ref_sz.y)
	if target.x <= 0.0 or target.y <= 0.0:
		return
	var sc := minf(target.x / fs.x, target.y / fs.y)
	node.scale = Vector2(sc, sc)


func _sync_overlay_node(overlay: AnimatedSprite2D) -> void:
	if not overlay.visible:
		return
	var anim: StringName = overlay.animation
	if overlay.sprite_frames == null or anim.is_empty():
		overlay.scale = Vector2.ONE
		return
	var fs := _anim_first_frame_size(overlay.sprite_frames, anim)
	if fs.x <= 0.0 or fs.y <= 0.0:
		overlay.scale = Vector2.ONE
		return
	_apply_overlay_scale(fs, _reference_size_for_overlay(), overlay)


func _sync_animated_sprite_scale() -> void:
	_sync_overlay_node(sprite)


func _on_hit_down() -> void:
	if idle_texture == null:
		return
	if _press_down_override():
		return
	sprite.visible = true
	sprite.play()
	_sync_animated_sprite_scale()


func _on_sprite_animation_finished() -> void:
	if not _animation_finished_override():
		sprite.visible = false


func _on_hit_pressed() -> void:
	interacted.emit()


func _press_down_override() -> bool:
	return false


func _animation_finished_override() -> bool:
	return false


func _center_sprite() -> void:
	if sprite:
		sprite.centered = true
		sprite.position = size * 0.5
		_sync_animated_sprite_scale()


func _fit_size() -> void:
	custom_minimum_size = _intrinsic_sprite_size() + Vector2(pad_h * 2.0, pad_v * 2.0)


func _intrinsic_sprite_size() -> Vector2:
	var w := 32.0
	var h := 32.0
	if idle_texture:
		var s := idle_texture.get_size()
		w = maxf(w, s.x)
		h = maxf(h, s.y)
	if sprite.sprite_frames != null and not sprite.animation.is_empty():
		var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		if tex:
			var s2 := tex.get_size()
			w = maxf(w, s2.x)
			h = maxf(h, s2.y)
	return Vector2(w, h)
