extends EnemyBase
## Conflicto de Merge: la sombra del jugador que guarda sus Bits.

var dash_timer := 2.0
var dash_t := 0.0
var dash_dir := Vector2.ZERO


func _setup() -> void:
	enemy_id = "conflicto_merge"
	max_hp = 5
	bits_drop = 0
	body_size = Vector2(40, 80)
	uses_gravity = false
	collision_mask = 0


func _ai(delta: float) -> void:
	var tp := to_player() + Vector2(0, -20)
	dash_timer -= delta
	if dash_t > 0.0:
		dash_t -= delta
		velocity = dash_dir * 620.0
	elif tp.length() < 650.0:
		velocity = velocity.lerp(tp.normalized() * 60.0, 0.05)
		if dash_timer <= 0.0:
			dash_timer = 2.6
			dash_t = 0.45
			dash_dir = tp.normalized()
			AudioManager.play_sfx("shade")
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.1)
	facing = signf(tp.x) if absf(tp.x) > 4.0 else facing
	position += velocity * delta + Vector2(0, sin(t * 2.0) * 0.3)


func _on_death() -> void:
	GameState.recover_shade()
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(2.4, 2.4, 2.6), 40, 600.0, 0.9, 0.5, Vector2.ZERO)


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var col := Color(0.01, 0.01, 0.02, 0.92)
	var c := Vector2(0, -40)
	var pts := PackedVector2Array()
	for i in 14:
		var a := PI + PI * i / 13.0
		pts.append(c + Vector2(cos(a) * 22, sin(a) * 30 - 8))
	for i in 6:
		pts.append(c + Vector2(22 - i * 8.8, 40 + sin(t * 7.0 + i) * 7.0))
	draw_colored_polygon(pts, col)
	# Cuernos < > oscuros.
	draw_polyline(PackedVector2Array([c + Vector2(-8, -34), c + Vector2(-20, -48), c + Vector2(-10, -60)]), col, 5.0, true)
	draw_polyline(PackedVector2Array([c + Vector2(8, -34), c + Vector2(20, -48), c + Vector2(10, -60)]), col, 5.0, true)
	eye(c + Vector2(-7, -14), 4.0, Color(2.6, 2.6, 2.8))
	eye(c + Vector2(7, -14), 4.0, Color(2.6, 2.6, 2.8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	var jitter := Vector2(randf_range(-1, 1), 0) if int(t * 10) % 7 == 0 else Vector2.ZERO
	draw_string(font, Vector2(-44, -104) + jitter, "<<<<<<< HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(2.2, 0.6, 0.6, 0.8))
	draw_string(font, Vector2(-44, 18) + jitter, ">>>>>>> main", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 1.6, 2.2, 0.8))
