class_name DaemonDesbocado
extends EnemyBase
## Daemon Desbocado: proceso en segundo plano sin límites de recursos. Cuando te
## detecta te persigue acelerando sin parar; si se pasa de largo y choca, se
## queda aturdido: es el momento de golpearlo.

enum S { WANDER, CHASE, STUNNED }

var s := S.WANDER
var timer := 0.0
var speed := 0.0
var home := Vector2.ZERO
var has_home := false


func _setup() -> void:
	enemy_id = "daemon_desbocado"
	max_hp = 4
	bits_drop = 9
	body_size = Vector2(46, 46)
	uses_gravity = false


func _ai(delta: float) -> void:
	if not has_home:
		home = global_position
		has_home = true
	timer -= delta
	var tp := to_player()
	match s:
		S.WANDER:
			var goal := home + Vector2(cos(t * 0.8) * 90.0, sin(t * 1.3) * 40.0)
			velocity = EnemyKit.steer(velocity, global_position, goal, 120.0, 500.0, delta)
			if tp.length() < 520.0 and timer <= 0.0:
				s = S.CHASE
				speed = 120.0
				timer = 4.0
				AudioManager.play_sfx("boss_roar", 0.5)
		S.CHASE:
			speed = minf(speed + 260.0 * delta, 720.0)
			var want := (tp + Vector2(0, -40)).normalized() * speed
			velocity = velocity.move_toward(want, 700.0 * delta)
			if get_slide_collision_count() > 0 and speed > 380.0:
				s = S.STUNNED
				timer = 1.5
				velocity = -velocity * 0.3
				Events.camera_shake.emit(5.0, 0.2)
				EnemyKit.tip("daemon", "El daemon acelera sin límite: haz que choque contra una pared y golpéalo aturdido")
			elif timer <= 0.0 or tp.length() > 900.0:
				s = S.WANDER
				timer = 1.5
		S.STUNNED:
			velocity = velocity.move_toward(Vector2(0, 60), 600.0 * delta)
			if timer <= 0.0:
				s = S.WANDER
				timer = 1.0
				home = global_position
	if absf(velocity.x) > 5.0:
		facing = signf(velocity.x)
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -23)
	var col := Color(2.6, 0.4, 0.4) if s == S.CHASE else Color(1.6, 0.6, 2.2)
	var heat := clampf(speed / 720.0, 0.0, 1.0) if s == S.CHASE else 0.0
	if s == S.CHASE:
		for i in 4:
			draw_circle(c - velocity.normalized() * (14.0 + i * 12.0), 14.0 - i * 3.0, Color(col, 0.18 - i * 0.04))
	draw_circle(c, 22.0, Color(0.1, 0.03, 0.06))
	draw_arc(c, 22.0, 0, TAU, 24, col, 2.5)
	# Cuernos.
	for sx: float in [-1.0, 1.0]:
		draw_line(c + Vector2(sx * 12, -16), c + Vector2(sx * 20, -34), col, 3.0)
	var spin := t * (4.0 + heat * 20.0)
	draw_arc(c, 12.0, spin, spin + PI, 12, Color(2.6, 1.6, 0.6), 2.0)
	if s == S.STUNNED:
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			draw_circle(c + Vector2(cos(a) * 22.0, -30.0 + sin(a) * 6.0), 3.5, Color(2.6, 2.2, 0.6))
	else:
		eye(c + Vector2(facing * 8, -2), 3.5, Color(2.8, 1.2, 0.4))
	EnemyKit.label(self, Vector2(0, -64), "CPU %d%%" % int(40 + heat * 60.0), 12, Color(col, 0.85))
