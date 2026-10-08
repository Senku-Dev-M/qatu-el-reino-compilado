extends Node2D
## Farol de la plaza. Si tiene `flag`, solo se enciende al cumplirse
## (progreso visible en el hub).

var room: RoomBase
var def: Dictionary
var t := 0.0
var lit := true
var light: PointLight2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	t = randf() * 10.0
	lit = not def.has("flag") or bool(GameState.get_flag(def.flag))
	light = FX.make_light(Color(1.0, 0.75, 0.4), 4.5, 1.1 if lit else 0.0)
	light.position = Vector2(0, -230)
	add_child(light)


func _process(delta: float) -> void:
	t += delta
	if lit:
		light.energy = 1.0 + sin(t * 8.0) * 0.06 + sin(t * 3.1) * 0.05
	queue_redraw()


func _draw() -> void:
	var dark := Color(0.05, 0.045, 0.05)
	draw_rect(Rect2(-8, -220, 16, 220), dark)
	draw_rect(Rect2(-22, -14, 44, 14), dark)
	draw_line(Vector2(0, -220), Vector2(34, -240), dark, 6.0)
	var lamp := Vector2(34, -222)
	draw_colored_polygon(PackedVector2Array([lamp + Vector2(-16, -20), lamp + Vector2(16, -20), lamp + Vector2(12, 16), lamp + Vector2(-12, 16)]), dark)
	if lit:
		var f := 0.9 + 0.1 * sin(t * 11.0)
		draw_circle(lamp, 40, Color(1.8, 1.1, 0.4, 0.12))
		draw_circle(lamp, 10 * f, Color(2.8, 1.3, 0.4))
	else:
		draw_circle(lamp, 8, Color(0.15, 0.12, 0.1))
