extends EnemyBase
## Fuerza Bruta: máquina fija que prueba contraseñas sin descanso y dispara
## ráfagas. Entre ráfaga y ráfaga queda expuesta.

var burst := 0
var shot_timer := 0.0
var pause := 2.0
var intento := 0


func _setup() -> void:
	enemy_id = "fuerza_bruta"
	max_hp = 5
	bits_drop = 10
	body_size = Vector2(64, 66)
	knock_resist = 0.9


func _ai(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = 0.0
	var tp := to_player()
	if absf(tp.x) > 5.0:
		facing = signf(tp.x)
	if burst > 0:
		shot_timer -= delta
		if shot_timer <= 0.0:
			burst -= 1
			shot_timer = 0.14
			intento += 1
			if tp.length() < 900.0:
				var dir := (tp + Vector2(0, -34)).normalized().rotated(randf_range(-0.12, 0.12))
				BossAttacks.projectile(get_parent(), global_position + Vector2(0, -40), dir * 520.0, 0.0, "%04d" % (intento % 10000))
				AudioManager.play_sfx("spit", 0.3)
	else:
		pause -= delta
		if pause <= 0.0 and absf(tp.x) < 700.0 and absf(tp.y) < 320.0:
			burst = 6
			pause = 2.6
			shot_timer = 0.0
	move_and_slide()


func _draw_body() -> void:
	var dark := Color(0.14, 0.12, 0.2)
	var col := Color(2.4, 0.8, 0.6)
	var body := Rect2(-32, -66, 64, 66)
	draw_rect(body, dark)
	draw_rect(body, Color(col, 0.55), false, 2.0)
	# Ruedas de combinación girando.
	for i in 4:
		var x := -24 + i * 16
		var spin := fmod(t * (3.0 + i) + i, 1.0)
		draw_rect(Rect2(x - 6, -56, 12, 30), Color(0.05, 0.05, 0.08))
		draw_string(UITheme.mono_font(), Vector2(x - 4, -40 + spin * 8.0), str((intento + i * 3) % 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(col, 0.9))
	# Cañón.
	draw_rect(Rect2(facing * 20 - 8, -30, 30 * facing, 14), dark)
	eye(Vector2(facing * 12, -18), 3.5, col if burst > 0 else Color(col, 0.5))
	draw_string(UITheme.mono_font(), Vector2(-40, -78), "intento %d" % intento, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(col, 0.85))
