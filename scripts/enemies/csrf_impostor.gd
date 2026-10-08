extends EnemyBase
## CSRF Impostor: se hace pasar por un Bit brillante. Cuando el jugador se
## acerca confiado, se revela y embiste (una petición falsificada que
## aprovecha la confianza del sitio).

var disguised := true
var lunge_cd := 0.0


func _setup() -> void:
	enemy_id = "csrf_impostor"
	max_hp = 3
	bits_drop = 8
	body_size = Vector2(48, 40)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	var tp := to_player()
	if disguised:
		velocity.x = 0.0
		contact.set_enabled(false)
		if tp.length() < 170.0:
			disguised = false
			contact.set_enabled(true)
			flash = 1.0
			AudioManager.play_sfx("boss_roar", 0.3)
			velocity = Vector2(signf(tp.x) * 520.0, -420.0)
			facing = signf(tp.x)
			if not GameState.get_flag("tip:csrf"):
				GameState.set_flag("tip:csrf")
				Events.notify.emit("¡No era un Bit! CSRF se aprovecha de la confianza")
		move_and_slide()
		return
	lunge_cd -= delta
	if is_on_floor():
		if lunge_cd <= 0.0 and absf(tp.x) < 360.0 and absf(tp.y) < 160.0:
			lunge_cd = 1.8
			facing = signf(tp.x)
			velocity = Vector2(facing * 560.0, -380.0)
		else:
			if is_wall_ahead() or is_edge_ahead():
				facing = -facing
			velocity.x = facing * 120.0
	move_and_slide()


func take_hit(hit: Dictionary) -> Dictionary:
	if disguised:
		disguised = false
		contact.set_enabled(true)
	return super.take_hit(hit)


func _draw_body() -> void:
	if disguised:
		var c := Vector2(0, -20 + sin(t * 3.0) * 4.0)
		draw_circle(c, 20, Color(2.2, 1.8, 0.8, 0.12))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(8, 0), c + Vector2(0, 10), c + Vector2(-8, 0)]), Color(2.4, 2.0, 0.9))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.08, 0.05, 0.03)
	var body := PackedVector2Array([Vector2(-26, 0), Vector2(-20, -34), Vector2(12, -40), Vector2(28, -16), Vector2(22, 0)])
	draw_colored_polygon(body, dark)
	draw_polyline(body, Color(2.2, 1.6, 0.5, 0.8), 2.0, true)
	# Máscara del Bit a medio caer.
	draw_colored_polygon(PackedVector2Array([Vector2(8, -34), Vector2(18, -26), Vector2(8, -18), Vector2(-2, -26)]), Color(2.4, 2.0, 0.9, 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	eye(Vector2(facing * 14, -24), 3.5, Color(2.6, 0.6, 0.4))
	draw_string(UITheme.mono_font(), Vector2(-24, -52), "CSRF", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.4, 1.2, 0.5, 0.9))
