class_name InyeccionSql
extends EnemyBase
## Inyección SQL: sombra que rompe las comillas del delimitador. Se agacha,
## apunta y dispara en línea recta una cadena maliciosa muy rápida; entre
## disparo y disparo avanza hacia ti. Salta la cadena o cúbrete.

enum S { WALK, AIM, RECOVER }

var s := S.WALK
var timer := 1.2


func _setup() -> void:
	enemy_id = "inyeccion_sql"
	max_hp = 4
	bits_drop = 8
	body_size = Vector2(44, 64)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	timer -= delta
	var tp := to_player()
	var near := absf(tp.x) < 620.0 and absf(tp.y) < 140.0
	match s:
		S.WALK:
			if near and tp.x != 0.0:
				facing = signf(tp.x)
			if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
				facing = -facing if not near else facing
				velocity.x = 0.0
			else:
				velocity.x = facing * (90.0 if near else 50.0)
			if near and timer <= 0.0:
				s = S.AIM
				timer = 0.6
		S.AIM:
			velocity.x = 0.0
			if timer <= 0.0:
				BossAttacks.projectile(get_parent(), global_position + Vector2(facing * 30, -36), Vector2(facing * 720.0, 0.0), 0.0, "' OR 1=1 --")
				AudioManager.play_sfx("spit", 0.1)
				s = S.RECOVER
				timer = 0.7
		S.RECOVER:
			velocity.x = -facing * 60.0 if not is_edge_ahead() else 0.0
			if timer <= 0.0:
				s = S.WALK
				timer = 1.8
	move_and_slide()


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var col := Color(2.4, 0.9, 0.3)
	var crouch := 10.0 if s == S.AIM else 0.0
	var dark := Color(0.05, 0.03, 0.03, 0.95)
	var step := sin(t * 7.0) * 3.0
	draw_line(Vector2(-8, -20), Vector2(-10 + step, 0), dark, 7.0)
	draw_line(Vector2(8, -20), Vector2(6 - step, 0), dark, 7.0)
	var body := PackedVector2Array([Vector2(-18, -20), Vector2(18, -20), Vector2(12, -64 + crouch), Vector2(-14, -60 + crouch)])
	draw_colored_polygon(body, dark)
	body.append(body[0])
	draw_polyline(body, col, 2.0)
	# Comilla rota que hace de arma.
	draw_string(UITheme.mono_font(), Vector2(14, -34 + crouch), "'", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)
	eye(Vector2(6, -52 + crouch), 3.5, Color(2.8, 1.2, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if s == S.AIM:
		var k := 1.0 - timer / 0.6
		draw_line(Vector2(facing * 30, -36), Vector2(facing * (30 + 400 * k), -36), Color(2.6, 0.6, 0.3, 0.4), 2.0)
	EnemyKit.label(self, Vector2(0, -74), "WHERE id=''", 12, Color(col, 0.8))
