class_name DamageArea
extends Area2D
## Área que daña al jugador por contacto (capa 7).

var damage := 1
var respawn := false


func _init() -> void:
	collision_layer = 1 << 6
	collision_mask = 0
	monitoring = false


func add_shape(shape: Shape2D, offset := Vector2.ZERO) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = offset
	add_child(cs)
	return cs


func set_enabled(on: bool) -> void:
	for c in get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", not on)
