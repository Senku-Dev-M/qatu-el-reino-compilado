extends "res://scripts/enemies/alt_ausente.gd"
## Desbordamiento: caja voladora de la que se sale el contenido (overflow).


func _setup() -> void:
	enemy_id = "desbordamiento"
	max_hp = 3
	bits_drop = 6
	body_size = Vector2(54, 40)
	uses_gravity = false


func _ai(delta: float) -> void:
	super._ai(delta)
	visibility = 1.0
	modulate.a = 1.0


func _draw_body() -> void:
	var c := Vector2(0, -20)
	var flap := sin(t * 12.0) * 6.0
	var box := Rect2(c - Vector2(24, 16), Vector2(48, 32))
	draw_rect(box, Color(0.08, 0.1, 0.14))
	draw_rect(box, Color(0.4, 1.4, 1.6), false, 2.0)
	# El texto se sale de la caja.
	var font := UITheme.mono_font()
	draw_string(font, c + Vector2(-20, 5), "contenido-largo", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.8, 0.6, 0.5, 0.9))
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([c + Vector2(side * 24, -6), c + Vector2(side * 46, -14 - flap), c + Vector2(side * 40, 8)]), Color(0.1, 0.12, 0.16))
	eye(c + Vector2(-8, -6), 2.5, Color(2.4, 2.4, 2.6))
	eye(c + Vector2(8, -6), 2.5, Color(2.4, 2.4, 2.6))
