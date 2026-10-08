class_name ContainerBox
extends CharacterBody2D
## Caja Contenedor: Bloque físico que sirve de plataforma y escudo temporal.

@export var duration := 10.0
var time_left := 10.0
var t := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	time_left = duration
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 56)
	cs.shape = rect
	cs.position = Vector2(0, -28)
	add_child(cs)

func _physics_process(delta: float) -> void:
	t += delta * 4.0
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	if not is_on_floor():
		velocity.y += 980.0 * delta
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var col := Color(0.2, 0.7, 1.0)
	var alpha := clampf(time_left / 2.0, 0.2, 1.0)
	draw_rect(Rect2(-26, -54, 52, 52), Color(0.05, 0.12, 0.2, alpha))
	draw_rect(Rect2(-26, -54, 52, 52), Color(col.r, col.g, col.b, alpha), false, 2.0)
	draw_line(Vector2(-20, -28), Vector2(20, -28), Color(col.r, col.g, col.b, alpha * 0.7), 2.0)
	draw_line(Vector2(0, -48), Vector2(0, -8), Color(col.r, col.g, col.b, alpha * 0.7), 2.0)
