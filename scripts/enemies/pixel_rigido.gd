extends "res://scripts/enemies/selector_universal.gd"
## Píxel Rígido: bloque de ancho fijo que cae desde el techo y golpea en área.


func _setup() -> void:
	enemy_id = "pixel_rigido"
	max_hp = 4
	bits_drop = 7
	body_size = Vector2(56, 48)
	uses_gravity = false


func _draw_body() -> void:
	var c := Vector2(0, -24)
	draw_line(c, Vector2(0, ceiling_y - global_position.y), Color(0.7, 0.6, 0.5, 0.35), 2.0)
	var r := Rect2(c - Vector2(28, 24), Vector2(56, 48))
	draw_rect(r, Color(0.16, 0.12, 0.1))
	draw_rect(r, Color(1.0, 0.6, 0.3), false, 3.0)
	# Reglas de medida fijas.
	for i in 5:
		draw_line(r.position + Vector2(8 + i * 10, 0), r.position + Vector2(8 + i * 10, 8), Color(1.0, 0.6, 0.3), 2.0)
	var glow := Color(2.4, 1.2, 0.4)
	if s == S.TELEGRAPH:
		var k := 1.0 - timer / 0.45
		draw_arc(c, RADIUS * k, 0, TAU, 48, Color(2.4, 1.0, 0.3, 0.6), 3.0, true)
		glow = Color(3.0, 2.0, 1.0)
	draw_string(UITheme.mono_font(), c + Vector2(-26, 8), "960px", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, glow)
