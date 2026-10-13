## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Preview of the sprite of a tower, trap or enemy scene, shared by the armory, the encyclopedia and the build cards.
class_name SpritePreview
extends RefCounted

const SPRITE_NODE_NAMES: Array[StringName] = [&"Sprite", &"AnimatedSprite2D", &"Sprite2D"]

## Animation shown by [member frames] (empty for a static sprite).
var animation: StringName = &""
var fps: float = 5.0
## Frames of the animated sprite, null for a static sprite.
var frames: SpriteFrames = null
## [member Node2D.modulate] of the sprite, [member CanvasItem.self_modulate] when it is not white.
var modulate: Color = Color.WHITE
var scale: Vector2 = Vector2.ONE
## First frame of the animation, or the texture of a static sprite. Null when the scene has no sprite.
var texture: Texture2D = null


## Reads the sprite of the instantiated scene [param root], which is left untouched. Returns an empty preview when it has no sprite.
static func from_node(root: Node) -> SpritePreview:
	var preview: SpritePreview = SpritePreview.new()
	preview._read_sprite(_find_sprite(root))
	return preview


## Instantiates [param scene] and reads its sprite, returns an empty preview when the scene is null or has no sprite.
static func from_scene(scene: PackedScene) -> SpritePreview:
	if scene == null:
		return SpritePreview.new()

	var root: Node = scene.instantiate()
	var preview: SpritePreview = from_node(root)
	root.free()
	return preview


static func _find_sprite(root: Node) -> Node:
	for node_name: StringName in SPRITE_NODE_NAMES:
		var named_sprite: Node = root.get_node_or_null(NodePath(node_name))
		if named_sprite is AnimatedSprite2D or named_sprite is Sprite2D:
			return named_sprite

	var animated_sprites: Array[Node] = root.find_children("*", "AnimatedSprite2D", true, false)
	if not animated_sprites.is_empty():
		return animated_sprites[0]
	var sprites: Array[Node] = root.find_children("*", "Sprite2D", true, false)
	return sprites[0] if not sprites.is_empty() else null


func _read_sprite(sprite: Node) -> void:
	if sprite is AnimatedSprite2D:
		var animated_sprite: AnimatedSprite2D = sprite
		modulate = animated_sprite.self_modulate if animated_sprite.self_modulate != Color.WHITE else animated_sprite.modulate
		scale = animated_sprite.scale
		if animated_sprite.sprite_frames == null or animated_sprite.sprite_frames.get_animation_names().is_empty():
			return
		var sprite_frames: SpriteFrames = animated_sprite.sprite_frames
		var animation_name: StringName = &"idle" if sprite_frames.has_animation(&"idle") else StringName(sprite_frames.get_animation_names()[0])
		frames = sprite_frames
		animation = animation_name
		fps = sprite_frames.get_animation_speed(animation_name)
		if sprite_frames.get_frame_count(animation_name) > 0:
			texture = sprite_frames.get_frame_texture(animation_name, 0)
	elif sprite is Sprite2D:
		var static_sprite: Sprite2D = sprite
		modulate = static_sprite.self_modulate if static_sprite.self_modulate != Color.WHITE else static_sprite.modulate
		scale = static_sprite.scale
		texture = static_sprite.texture
