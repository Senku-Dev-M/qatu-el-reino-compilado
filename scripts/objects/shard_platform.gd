class_name ShardPlatform
extends AnimatableBody2D
## Plataforma de Sharding: Se eleva o desplaza al resolver peticiones concurrentes.

var room: RoomBase
var def: Dictionary

func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(96, 20)
	cs.shape = rect
	cs.position = Vector2(0, -10)
	add_child(cs)

func _draw() -> void:
	var col := Color(1.8, 0.6, 2.2)
	draw_rect(Rect2(-48, -20, 96, 20), Color(0.12, 0.05, 0.15))
	draw_rect(Rect2(-48, -20, 96, 20), col, false, 2.0)
