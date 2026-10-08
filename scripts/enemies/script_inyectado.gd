extends EnemyBase
## Script Inyectado: rastrero que se detiene y escupe etiquetas <script> en
## parábola (texto de usuario sin escapar que el navegador ejecuta).

var spit_cd := 2.0
var windup := 0.0


func _setup() -> void:
	enemy_id = "script_inyectado"
	max_hp = 3
	bits_drop = 6
	body_size = Vector2(60, 36)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	spit_cd -= delta
	var tp := to_player()
	if windup > 0.0:
		windup -= delta
		velocity.x = 0.0
		if windup <= 0.0:
			var dir := signf(tp.x) if tp.x != 0.0 else facing
			facing = dir
			var dist := clampf(absf(tp.x), 120.0, 520.0)
			BossAttacks.projectile(get_parent(), global_position + Vector2(dir * 30, -40), Vector2(dir * dist * 1.1, -620.0), 1400.0, "<script>")
			AudioManager.play_sfx("spit", 0.2)
			spit_cd = 2.6
	elif spit_cd <= 0.0 and absf(tp.x) < 520.0 and absf(tp.y) < 260.0:
		windup = 0.45
		facing = signf(tp.x)
	elif is_on_floor():
		if is_wall_ahead() or is_edge_ahead():
			facing = -facing
		velocity.x = facing * 80.0
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -18)
	var puff := 1.0 + (0.18 if windup > 0.0 else 0.0) * sin(t * 40.0)
	var dark := Color(0.06, 0.04, 0.08)
	for i in 4:
		var lx := -22 + i * 14 + sin(t * 10.0 + i) * 3.0
		draw_line(Vector2(lx, -6), Vector2(lx - 4, 0), dark, 4.0)
	draw_rect(Rect2(c - Vector2(30, 16) * puff, Vector2(60, 32) * puff), dark)
	draw_rect(Rect2(c - Vector2(30, 16) * puff, Vector2(60, 32) * puff), Color(1.8, 0.5, 1.2), false, 2.0)
	var font := UITheme.mono_font()
	draw_string(font, c + Vector2(-26, 6), "</>", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(2.4, 0.7, 1.6))
	eye(c + Vector2(facing * 20, -8), 3.0, Color(2.4, 0.6, 1.8))
