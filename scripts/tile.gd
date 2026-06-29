extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var grid_pos: Vector2 = Vector2.ZERO
var type: int = 0

const TYPE_ANIMATIONS = [
	"type_0",
	"type_1",
	"type_2",
	"type_3",
	"type_4",
	"type_5",
    "type_6"
]

func init(pos: Vector2, piece_type: int):
	await ready
	grid_pos = pos
	type = piece_type
	update_sprite()

func update_sprite():
	if sprite == null:
		return
	
	if sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
		sprite.frame = type
		sprite.pause()

func select():
	scale = Vector2(1.2, 1.2)

func deselect():
	scale = Vector2(1, 1)

func disappear():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	queue_free()

func appear():
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
