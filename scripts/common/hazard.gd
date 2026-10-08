class_name Hazard
extends Area2D
## Zona que daña al jugador (capa 7). Si `respawn` es true, devuelve al
## jugador al último suelo seguro (pinchos, vacío). También admite pogo.

@export var damage := 1
@export var respawn := true
@export var pogo := true


func _init() -> void:
	collision_layer = (1 << 6) | (1 << 4)  # capa 7 (daño) y 5 (golpeable para pogo)
	collision_mask = 0
	monitoring = false
	monitorable = true


func take_hit(_hit: Dictionary) -> Dictionary:
	return {"pogo": pogo, "energy": false, "solid": true}


func add_rect(rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.get_center()
	add_child(cs)
