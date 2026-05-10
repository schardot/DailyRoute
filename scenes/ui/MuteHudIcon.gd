extends HudAnimatedIconButton

@export var idle_texture_muted: Texture2D

@onready var overlay_unmute: AnimatedSprite2D = $OverlayUnmute


func _ready() -> void:
	super._ready()
	overlay_unmute.animation_finished.connect(_on_sprite_animation_finished)
	overlay_unmute.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_unmute.visible = false
	interacted.connect(_on_interacted)
	SoundController.muted_changed.connect(func(_m: bool) -> void: _refresh_underlay_texture())
	_refresh_underlay_texture()


func _on_interacted() -> void:
	SoundController.toggle_mute()


func _refresh_underlay_texture() -> void:
	if idle_rect == null:
		return
	if idle_texture == null and idle_texture_muted == null:
		return
	var muted := SoundController.is_muted()
	if muted:
		idle_rect.texture = idle_texture_muted if idle_texture_muted else idle_texture
	else:
		idle_rect.texture = idle_texture
	idle_rect.visible = idle_rect.texture != null


func _press_down_override() -> bool:
	var muted := SoundController.is_muted()
	sprite.visible = false
	overlay_unmute.visible = false
	if muted:
		overlay_unmute.visible = true
		overlay_unmute.play()
	else:
		sprite.visible = true
		sprite.play()
	call_deferred("_sync_animated_sprite_scale")
	return true


func _animation_finished_override() -> bool:
	sprite.visible = false
	overlay_unmute.visible = false
	_refresh_underlay_texture()
	return true


func _sync_animated_sprite_scale() -> void:
	if overlay_unmute.visible:
		_sync_overlay_node(overlay_unmute)
	elif sprite.visible:
		_sync_overlay_node(sprite)


func _center_sprite() -> void:
	sprite.centered = true
	sprite.position = size * 0.5
	overlay_unmute.centered = true
	overlay_unmute.position = size * 0.5
	_sync_animated_sprite_scale()


func _reference_size_for_overlay() -> Vector2:
	var muted := SoundController.is_muted()
	if muted:
		if idle_texture_muted:
			return idle_texture_muted.get_size()
		if idle_texture:
			return idle_texture.get_size()
		return Vector2.ZERO
	return idle_texture.get_size() if idle_texture else Vector2.ZERO


func _intrinsic_sprite_size() -> Vector2:
	var ms := super._intrinsic_sprite_size()
	if idle_texture_muted:
		var s := idle_texture_muted.get_size()
		ms.x = maxf(ms.x, s.x)
		ms.y = maxf(ms.y, s.y)
	if overlay_unmute.sprite_frames != null and not overlay_unmute.animation.is_empty():
		var ut: Texture2D = overlay_unmute.sprite_frames.get_frame_texture(overlay_unmute.animation, 0)
		if ut:
			var su := ut.get_size()
			ms.x = maxf(ms.x, su.x)
			ms.y = maxf(ms.y, su.y)
	return ms
