extends EnemyBase
## Log Síncrono: una máquina de escribir que detiene todo mientras escribe
## cada registro y después suelta una ráfaga de líneas.

var phase_timer := 1.5
var writing := true
var shots := 0
var shot_timer := 0.0


func _setup() -> void:
	enemy_id = "log_sincrono"
	max_hp = 4
	bits_drop = 8
	body_size = Vector2(70, 50)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = 0.0
	phase_timer -= delta
	var tp := to_player()
	if writing:
		if phase_timer <= 0.0:
			writing = false
			shots = 3
			shot_timer = 0.0
	else:
		shot_timer -= delta
		if shots > 0 and shot_timer <= 0.0:
			shots -= 1
			shot_timer = 0.22
			if tp.length() < 800.0:
				BossAttacks.projectile(get_parent(), global_position + Vector2(0, -40), (tp + Vector2(0, -30)).normalized() * 420.0, 0.0, "log")
				AudioManager.play_sfx("spit", 0.25)
		if shots <= 0 and shot_timer <= 0.0:
			writing = true
			phase_timer = 2.0
	if absf(tp.x) > 5.0:
		facing = signf(tp.x)
	move_and_slide()


func _draw_body() -> void:
	var dark := Color(0.12, 0.1, 0.09)
	var shake := Vector2(sin(t * 60.0) * 1.5, 0) if writing else Vector2.ZERO
	draw_rect(Rect2(Vector2(-35, -40) + shake, Vector2(70, 40)), dark)
	draw_rect(Rect2(Vector2(-35, -40) + shake, Vector2(70, 40)), Color(0.8, 0.6, 0.4), false, 2.0)
	for i in 3:
		for k in 6:
			draw_circle(Vector2(-25 + k * 10, -28 + i * 10) + shake, 2.5, Color(0.6, 0.5, 0.4))
	# Hoja con el registro.
	var paper := Rect2(Vector2(-22, -74) + shake, Vector2(44, 34))
	draw_rect(paper, Color(0.9, 0.86, 0.75))
	var lines := int(fmod(t * (4.0 if writing else 0.0), 4.0))
	for i in lines:
		draw_line(paper.position + Vector2(5, 8 + i * 7), paper.position + Vector2(38, 8 + i * 7), Color(0.3, 0.25, 0.2), 1.5)
	eye(Vector2(facing * 18, -16), 3.0, Color(2.4, 1.0, 0.4))
	var font := UITheme.mono_font()
	draw_string(font, Vector2(-44, -84), "escribiendo…" if writing else "flush()", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(2.2, 1.5, 0.7, 0.85))
