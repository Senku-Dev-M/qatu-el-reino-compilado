extends EnemyBase
## Payload sin Comprimir: un bloque enorme y lento. Cada golpe lo comprime:
## se hace más pequeño y más rápido.

var compression := 0.0  # 0 = sin comprimir, 1 = comprimido al máximo
var charge_cd := 2.5


func _setup() -> void:
	enemy_id = "payload_gigante"
	max_hp = 6
	bits_drop = 12
	body_size = Vector2(110, 96)
	knock_resist = 0.8


func take_hit(hit: Dictionary) -> Dictionary:
	var r := super.take_hit(hit)
	if not dead:
		compression = clampf(1.0 - float(hp) / max_hp, 0.0, 1.0)
		_apply_compression.call_deferred()
		if not GameState.get_flag("tip:gzip"):
			GameState.set_flag("tip:gzip")
			Events.notify.emit("Cada golpe lo comprime: más pequeño, pero más rápido")
	return r


func _apply_compression() -> void:
	var s := 1.0 - compression * 0.45
	(body_shape.shape as RectangleShape2D).size = body_size * s
	body_shape.position = Vector2(0, -body_size.y * s * 0.5)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	charge_cd -= delta
	var speed := 40.0 + compression * 170.0
	var tp := to_player()
	if is_on_floor():
		if charge_cd <= 0.0 and absf(tp.x) < 420.0 and absf(tp.y) < 150.0:
			facing = signf(tp.x)
			velocity.x = facing * (260.0 + compression * 260.0)
			charge_cd = 2.2
		elif absf(velocity.x) <= speed + 5.0:
			if is_wall_ahead() or is_edge_ahead():
				facing = -facing
			velocity.x = facing * speed
		else:
			velocity.x = move_toward(velocity.x, facing * speed, 500.0 * delta)
			if is_wall_ahead() or is_edge_ahead():
				velocity.x = 0.0
				facing = -facing
	move_and_slide()


func _draw_body() -> void:
	var s := 1.0 - compression * 0.45
	var size := body_size * s
	var r := Rect2(Vector2(-size.x * 0.5, -size.y), size)
	draw_rect(r, Color(0.22, 0.16, 0.1))
	draw_rect(r, Color(1.0, 0.7, 0.35), false, 3.0)
	# Líneas de datos.
	for i in int(size.y / 14.0) - 1:
		var w := size.x * (0.4 + 0.5 * absf(sin(i * 1.7)))
		draw_line(r.position + Vector2(10, 14 + i * 14), r.position + Vector2(10 + w - 20, 14 + i * 14), Color(0.8, 0.6, 0.35, 0.6), 3.0)
	eye(Vector2(facing * size.x * 0.25, -size.y * 0.75), 4.0, Color(2.4, 1.2, 0.4))
	var kb := int(4200.0 * (1.0 - compression * 0.8))
	var text := ("%.1f MB" % (kb / 1000.0)) if compression < 0.01 else ("gzip %d KB" % kb)
	draw_string(UITheme.mono_font(), Vector2(-size.x * 0.5, -size.y - 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.4, 1.5, 0.6, 0.9))
