class_name LogicaEnVista
extends EnemyBase
## Lógica en la Vista: criatura caótica. Salta hacia ti a intervalos
## irregulares y, en lo alto del salto, lanza consultas SQL en parábola (mezcla
## datos y presentación donde no toca).

var jump_cd := 1.2
var threw := false


func _setup() -> void:
	enemy_id = "logica_en_vista"
	max_hp = 4
	bits_drop = 8
	body_size = Vector2(46, 46)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	var tp := to_player()
	var near := absf(tp.x) < 560.0 and absf(tp.y) < 260.0
	if is_on_floor():
		threw = false
		jump_cd -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		if is_wall_ahead() or is_edge_ahead():
			facing = -facing
		if jump_cd <= 0.0:
			if near and tp.x != 0.0:
				facing = signf(tp.x)
			var dist := randf_range(160.0, 320.0)
			velocity = Vector2(facing * dist, -randf_range(620.0, 860.0))
			if is_edge_ahead() and not near:
				velocity.x = 0.0
			jump_cd = randf_range(0.6, 1.6)
	elif not threw and velocity.y > -60.0 and near:
		threw = true
		var target := global_position + tp
		var dx := clampf(target.x - global_position.x, -420.0, 420.0)
		BossAttacks.projectile(get_parent(), global_position + Vector2(0, -40), Vector2(dx * 1.2, -380.0), 1400.0, "SQL")
		AudioManager.play_sfx("spit", 0.3)
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -24)
	var col := Color(2.2, 1.6, 0.4)
	var squash := Vector2(1.15, 0.85) if is_on_floor() else Vector2(0.9, 1.1)
	draw_set_transform(c, sin(t * 3.0) * 0.15, squash)
	draw_rect(Rect2(-22, -22, 44, 44), Color(0.12, 0.09, 0.03))
	draw_rect(Rect2(-22, -22, 44, 44), col, false, 2.0)
	draw_string(UITheme.mono_font(), Vector2(-20, -4), "<td>", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col, 0.9))
	draw_string(UITheme.mono_font(), Vector2(-20, 14), "=SUM", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(2.4, 0.6, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	eye(c + Vector2(-8, -30), 3.0, col)
	eye(c + Vector2(10, -32), 4.0, Color(2.4, 0.6, 0.5))
