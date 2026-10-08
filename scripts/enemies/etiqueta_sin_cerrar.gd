extends EnemyBase
## Rastrero que patrulla y deja un rastro corrupto (etiqueta sin cerrar).

var trail_timer := 0.0


func _setup() -> void:
	enemy_id = "etiqueta_sin_cerrar"
	max_hp = 3
	hp = 3
	bits_drop = 4
	body_size = Vector2(66, 34)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
		facing = -facing
	velocity.x = facing * 115.0
	move_and_slide()
	trail_timer -= delta
	if trail_timer <= 0.0 and is_on_floor():
		trail_timer = 0.5
		var seg := TrailSegment.new()
		get_parent().add_child(seg)
		seg.global_position = global_position + Vector2(-facing * 30, 0)


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.06, 0.03, 0.07)
	var shell := Color(0.16, 0.08, 0.18)
	var wave := t * 10.0
	# Segmentos con forma de "<".
	for i in 4:
		var x := -26 + i * 17.0
		var y := -16 + sin(wave + i) * 2.0
		draw_circle(Vector2(x, y), 15 - i * 0.5, dark)
		draw_polyline(PackedVector2Array([Vector2(x + 6, y - 10), Vector2(x - 4, y), Vector2(x + 6, y + 8)]), shell, 4.0, true)
		# Patas.
		var leg := sin(wave * 1.3 + i * 1.7) * 4.0
		draw_line(Vector2(x, y + 10), Vector2(x - 4 + leg, 0), dark, 3.0)
	# Cabeza con "<p" brillante.
	var head := Vector2(32, -18 + sin(wave) * 2.0)
	draw_circle(head, 16, dark)
	eye(head + Vector2(6, -3), 3.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-22, -34), "<p", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(2.2, 0.5, 1.8, 0.9))
