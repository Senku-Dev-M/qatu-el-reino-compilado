class_name XssFantasma
extends EnemyBase
## Espectro XSS: mantiene la distancia y lanza <script> que te persiguen
## durante un segundo y medio (código inyectado que se ejecuta en tu página).
## Golpear un script lo destruye; acercarse al espectro lo hace huir.

const HOMING_TIME := 1.5

var cd := 1.8
var scripts: Array[Node2D] = []
var ages: Array[float] = []
var home := Vector2.ZERO
var has_home := false


func _setup() -> void:
	enemy_id = "xss_fantasma"
	max_hp = 3
	bits_drop = 8
	body_size = Vector2(44, 56)
	uses_gravity = false


func _ai(delta: float) -> void:
	if not has_home:
		home = global_position
		has_home = true
	cd -= delta
	var tp := to_player()
	var dist := tp.length()
	var goal := home + Vector2(sin(t * 0.8) * 60.0, sin(t * 1.6) * 20.0)
	if dist < 700.0:
		if tp.x != 0.0:
			facing = signf(tp.x)
		# Busca quedarse a ~320 px del jugador.
		goal = global_position + tp - tp.normalized() * 320.0 + Vector2(0, -80)
		if cd <= 0.0:
			cd = 2.6
			var p := EnemyKit.shoot_at(self, global_position + Vector2(0, -30), global_position + tp, 200.0, "<script>")
			scripts.append(p)
			ages.append(0.0)
	velocity = EnemyKit.steer(velocity, global_position, goal, 160.0, 500.0, delta)
	move_and_slide()
	_steer_scripts(delta)


func _steer_scripts(delta: float) -> void:
	var pl := player()
	for i in range(scripts.size() - 1, -1, -1):
		var sc := scripts[i]
		ages[i] += delta
		if not is_instance_valid(sc) or ages[i] > HOMING_TIME or pl == null:
			scripts.remove_at(i)
			ages.remove_at(i)
			continue
		var want := (pl.global_position + Vector2(0, -40) - sc.global_position).normalized() * 260.0
		var cur: Vector2 = sc.get("velocity")
		sc.set("velocity", cur.move_toward(want, 520.0 * delta))


func _draw_body() -> void:
	var c := Vector2(0, -30)
	var col := Color(1.6, 0.5, 2.6)
	var a := 0.7 + 0.2 * sin(t * 3.0)
	draw_circle(c, 34.0, Color(col, 0.08))
	var pts := PackedVector2Array()
	for i in 10:
		var ang := PI + i * PI / 9.0
		pts.append(c + Vector2(cos(ang) * 20.0, sin(ang) * 20.0))
	for i in 5:
		pts.append(c + Vector2(20.0 - i * 10.0, 26.0 + 8.0 * sin(t * 5.0 + i)))
	draw_colored_polygon(pts, Color(0.07, 0.03, 0.1, a))
	pts.append(pts[0])
	draw_polyline(pts, Color(col, a), 2.0)
	EnemyKit.label(self, c + Vector2(0, 6), "</>", 16, Color(col, 0.95))
	eye(c + Vector2(facing * 7, -10), 3.0, Color(2.6, 1.0, 2.6))
	EnemyKit.label(self, Vector2(0, -64), "innerHTML", 12, Color(col, 0.8))
