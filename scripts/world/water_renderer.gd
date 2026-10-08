class_name WaterRenderer
extends Node2D
## Agua animada que sustituye el dibujo de los pinchos en los temas con
## `water: true`. El daño sigue siendo el de las casillas `^`.

const TILE := 64

var runs: Array[Rect2] = []
var th: Dictionary
var t := 0.0


func setup(rows: PackedStringArray, p_theme: Dictionary) -> void:
	th = p_theme
	z_index = 1
	for y in rows.size():
		var x := 0
		while x < rows[y].length():
			if rows[y][x] == "^":
				var x0 := x
				while x < rows[y].length() and rows[y][x] == "^":
					x += 1
				runs.append(Rect2(x0 * TILE, y * TILE + 18, (x - x0) * TILE, TILE - 18))
			else:
				x += 1


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var deep: Color = th.get("water_deep", Color(0.02, 0.12, 0.16))
	var surface: Color = th.get("water_surface", Color(0.5, 2.0, 2.2))
	for r in runs:
		var pts := PackedVector2Array()
		var x := r.position.x - 4
		while x <= r.end.x + 4:
			pts.append(Vector2(x, r.position.y + sin(x * 0.03 + t * 2.4) * 4.0 + sin(x * 0.011 - t * 1.3) * 3.0))
			x += 10.0
		var poly := pts.duplicate()
		poly.append(Vector2(r.end.x + 4, r.end.y + 6))
		poly.append(Vector2(r.position.x - 4, r.end.y + 6))
		draw_colored_polygon(poly, Color(deep, 0.92))
		draw_polyline(pts, Color(surface, 0.9), 3.0, true)
		# Espuma y corriente.
		for i in int(r.size.x / 40.0):
			var fx := r.position.x + fmod(i * 40.0 + t * 60.0, r.size.x)
			var fy := r.position.y + 14 + (i % 3) * 10
			draw_line(Vector2(fx, fy), Vector2(fx + 18, fy), Color(surface, 0.25), 2.0)
		# Resplandor bajo la superficie.
		draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, 10)), Color(surface, 0.08))
