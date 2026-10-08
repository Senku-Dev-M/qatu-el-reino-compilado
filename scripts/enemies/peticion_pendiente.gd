extends EnemyBase
## Petición Pendiente: orbe volador que gira mientras espera respuesta. En
## estado «pending» ignora los golpes; al resolverse dispara la respuesta y
## queda expuesto unos segundos.

var home := Vector2.ZERO
var phase_timer := 3.0
var pending := true


func _setup() -> void:
	enemy_id = "peticion_pendiente"
	max_hp = 3
	bits_drop = 6
	body_size = Vector2(50, 50)
	uses_gravity = false
	collision_mask = 0


func _after_setup() -> void:
	position.y -= 140
	home = position
	phase_timer = randf_range(2.0, 3.5)


func take_hit(hit: Dictionary) -> Dictionary:
	if pending and not dead:
		flash = 0.4
		AudioManager.play_sfx("sello_bad", 0.2)
		if not GameState.get_flag("tip:pendiente"):
			GameState.set_flag("tip:pendiente")
			Events.notify.emit("Está pendiente: espera a que se resuelva para golpearla")
		return {"solid": true, "energy": false, "pogo": true}
	return super.take_hit(hit)


func _ai(delta: float) -> void:
	phase_timer -= delta
	var tp := to_player()
	if phase_timer <= 0.0:
		pending = not pending
		if pending:
			phase_timer = 3.0
		else:
			phase_timer = 2.2
			if tp.length() < 700.0:
				BossAttacks.projectile(get_parent(), global_position + Vector2(0, -25), (tp + Vector2(0, -30)).normalized() * 360.0, 0.0, "200")
				AudioManager.play_sfx("spit", 0.2)
	var goal := home + Vector2(sin(t * 0.8) * 110.0, sin(t * 1.6) * 26.0)
	if not pending and tp.length() < 500.0:
		goal = home + Vector2(clampf(tp.x, -160, 160), 30)
	position = position.lerp(goal, 1.0 - exp(-2.0 * delta))
	facing = signf(tp.x) if absf(tp.x) > 5.0 else facing


func _draw_body() -> void:
	var c := Vector2(0, -25)
	var core := Color(2.4, 1.7, 0.5) if pending else Color(0.5, 2.2, 2.3)
	draw_circle(c, 30, Color(core, 0.1))
	draw_circle(c, 18, Color(0.04, 0.06, 0.08))
	if pending:
		# Indicador de carga girando.
		for i in 8:
			var a := t * 6.0 + TAU * i / 8.0
			draw_circle(c + Vector2(cos(a), sin(a)) * 26, 3.0 + i * 0.4, Color(core, 0.2 + i * 0.1))
	else:
		draw_arc(c, 24, 0, TAU, 32, core, 3.0, true)
	eye(c + Vector2(-6, -2), 3.0, core)
	eye(c + Vector2(6, -2), 3.0, core)
	var font := UITheme.mono_font()
	var text := "pending…" if pending else "resolved"
	draw_string(font, Vector2(-36, -66), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(core, 0.85))
