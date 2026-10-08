class_name TrailSegment
extends DamageArea
## Rastro corrupto que deja la Etiqueta Sin Cerrar.

var life := 2.4
var age := 0.0


func _ready() -> void:
	var s := RectangleShape2D.new()
	s.size = Vector2(38, 12)
	add_shape(s, Vector2(0, -6))
	z_index = -1


func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	if age > life - 0.4:
		set_enabled(false)
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - age / life
	var col := Color(2.0, 0.35, 1.6, 0.8 * k)
	draw_line(Vector2(-20, -3), Vector2(20, -3), col, 5.0 * k + 1.0, true)
	draw_circle(Vector2(sin(age * 5.0) * 10, -6), 3.0 * k, col)
