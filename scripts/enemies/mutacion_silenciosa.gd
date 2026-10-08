class_name MutacionSilenciosa
extends EnemyBase
## Mutante Silencioso: cambia un operador en cada golpe que recibe (como las
## pruebas de mutación) y con él su ataque: «>» se lanza en picado, «==» dispara
## dos proyectiles y «&&» orbita rápido a tu alrededor.

const OPS: Array[String] = [">", "==", "&&"]

var op := 0
var cd := 1.6
var timer := 0.0
var dive := Vector2.ZERO
var home := Vector2.ZERO
var has_home := false


func _setup() -> void:
	enemy_id = "mutacion_silenciosa"
	max_hp = 5
	bits_drop = 10
	body_size = Vector2(44, 44)
	uses_gravity = false


func take_hit(hit: Dictionary) -> Dictionary:
	var r := super.take_hit(hit)
	if not dead:
		op = (op + 1) % OPS.size()
		cd = 0.9
		timer = 0.0
		FX.burst(get_parent(), global_position + Vector2(0, -22), Color(0.8, 2.4, 1.6), 12, 300.0, 0.4, 0.3, Vector2.ZERO)
		EnemyKit.tip("mutante", "El mutante cambia de operador (y de ataque) cada vez que lo golpeas")
	return r


func _ai(delta: float) -> void:
	if not has_home:
		home = global_position
		has_home = true
	cd -= delta
	timer -= delta
	var tp := to_player()
	var near := tp.length() < 560.0
	if near and tp.x != 0.0:
		facing = signf(tp.x)
	match op:
		0:  # ">": picado
			if timer > 0.0:
				pass
			elif near and cd <= 0.0:
				dive = (tp + Vector2(0, -30)).normalized() * 560.0
				velocity = dive
				timer = 0.55
				cd = 2.0
				AudioManager.play_sfx("spit", 0.2)
			else:
				velocity = EnemyKit.steer(velocity, global_position, home + Vector2(0, sin(t * 2.0) * 30.0), 180.0, 700.0, delta)
		1:  # "==": dos disparos
			var goal := home + Vector2(sin(t) * 80.0, 0)
			velocity = EnemyKit.steer(velocity, global_position, goal, 120.0, 500.0, delta)
			if near and cd <= 0.0:
				cd = 1.8
				var from := global_position + Vector2(0, -22)
				EnemyKit.fan(self, from, global_position + tp + Vector2(0, -40), 360.0, 2, 0.18, "==")
		2:  # "&&": órbita
			var center := global_position + tp + Vector2(0, -60) if near else home
			var ang := t * 2.6
			var goal := center + Vector2(cos(ang) * 170.0, sin(ang) * 70.0)
			velocity = EnemyKit.steer(velocity, global_position, goal, 360.0, 1400.0, delta)
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -22)
	var cols: Array[Color] = [Color(2.6, 0.7, 0.4), Color(0.5, 1.6, 2.6), Color(0.8, 2.4, 0.9)]
	var col := cols[op]
	var pulse := 1.0 + 0.08 * sin(t * 7.0)
	var pts := PackedVector2Array()
	for i in 8:
		var rr := (22.0 if i % 2 == 0 else 14.0) * pulse
		pts.append(c + Vector2.RIGHT.rotated(i * TAU / 8.0 + t * (0.5 + op)) * rr)
	draw_colored_polygon(pts, Color(0.05, 0.08, 0.07))
	pts.append(pts[0])
	draw_polyline(pts, col, 2.0)
	EnemyKit.label(self, c + Vector2(0, 7), OPS[op], 18, col)
	EnemyKit.label(self, Vector2(0, -54), "mutante", 12, Color(col, 0.8))
