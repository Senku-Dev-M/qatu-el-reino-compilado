class_name StatelessDrone
extends EnemyBase
## Dron Sin Estado: patrulla un patrón fijo (no recuerda nada entre peticiones).
## Cada cierto tiempo toma la posición del jugador en ese instante y se lanza
## en picado hacia ella; después vuelve a su ruta como si nada hubiera pasado.

enum S { PATROL, AIM, DIVE, RETURN }

var s := S.PATROL
var home := Vector2.ZERO
var has_home := false
var timer := 2.0
var target := Vector2.ZERO


func _setup() -> void:
	enemy_id = "stateless_drone"
	max_hp = 3
	bits_drop = 6
	body_size = Vector2(48, 32)
	uses_gravity = false


func _ai(delta: float) -> void:
	if not has_home:
		home = global_position
		has_home = true
	timer -= delta
	var tp := to_player()
	match s:
		S.PATROL:
			var goal := home + Vector2(sin(t * 0.9) * 150.0, sin(t * 1.8) * 26.0)
			velocity = EnemyKit.steer(velocity, global_position, goal, 220.0, 900.0, delta)
			if absf(velocity.x) > 5.0:
				facing = signf(velocity.x)
			if timer <= 0.0 and tp.length() < 460.0:
				s = S.AIM
				timer = 0.5
				velocity = Vector2.ZERO
				# Sin estado: solo usa la posición de este instante.
				target = global_position + tp + Vector2(0, -30)
		S.AIM:
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if timer <= 0.0:
				s = S.DIVE
				timer = 0.9
				velocity = (target - global_position).normalized() * 640.0
				AudioManager.play_sfx("spit", 0.2)
		S.DIVE:
			if timer <= 0.0 or get_slide_collision_count() > 0 or global_position.distance_to(target) < 24.0:
				s = S.RETURN
				timer = 1.2
		S.RETURN:
			velocity = EnemyKit.steer(velocity, global_position, home, 260.0, 1200.0, delta)
			if global_position.distance_to(home) < 30.0 or timer <= -2.0:
				s = S.PATROL
				timer = 2.4
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -16)
	var col := Color(2.6, 0.8, 0.5) if s == S.AIM else Color(0.6, 1.8, 2.6)
	var dark := Color(0.05, 0.07, 0.1)
	for sx: float in [-1.0, 1.0]:
		var rp := c + Vector2(sx * 26, -10)
		draw_line(c + Vector2(sx * 12, -4), rp, dark, 3.0)
		var spin := absf(sin(t * 40.0)) * 16.0
		draw_line(rp - Vector2(spin, 0), rp + Vector2(spin, 0), Color(col, 0.6), 2.0)
	draw_rect(Rect2(c - Vector2(20, 12), Vector2(40, 24)), dark)
	draw_rect(Rect2(c - Vector2(20, 12), Vector2(40, 24)), col, false, 2.0)
	eye(c + Vector2(facing * 8, 0), 4.0, col)
	if s == S.AIM:
		draw_line(c, target - global_position, Color(2.6, 0.6, 0.4, 0.5), 2.0)
	EnemyKit.label(self, Vector2(0, -38), "GET /", 13, Color(col, 0.8))
