class_name RenderBloqueante
extends EnemyBase
## Render Bloqueante: aparición que flota despacio hacia ti. Carga una esfera de
## «loading…» enorme y lenta que ocupa medio pasillo: mientras está en el aire
## hay que esquivarla por encima o por debajo (bloquea el hilo principal).

var charge := 0.0
var cd := 2.5
var home_y := 0.0
var has_home := false


func _setup() -> void:
	enemy_id = "render_bloqueante"
	max_hp = 4
	bits_drop = 8
	body_size = Vector2(52, 64)
	uses_gravity = false


func _ai(delta: float) -> void:
	if not has_home:
		home_y = global_position.y
		has_home = true
	var tp := to_player()
	cd -= delta
	if charge > 0.0:
		charge -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		if charge <= 0.0:
			var p := EnemyKit.shoot_at(self, global_position + Vector2(facing * 30, -40), global_position + tp + Vector2(0, -40), 170.0, "loading…")
			p.scale = Vector2(2.2, 2.2)
			cd = 3.4
	else:
		var goal := Vector2(global_position.x, home_y + sin(t * 1.4) * 30.0)
		if tp.length() < 700.0:
			goal.x += signf(tp.x) * 40.0
			if tp.x != 0.0:
				facing = signf(tp.x)
			if cd <= 0.0:
				charge = 0.9
		velocity = EnemyKit.steer(velocity, global_position, goal, 60.0, 300.0, delta)
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -34)
	var col := Color(0.9, 1.2, 2.4)
	var a := 0.55 + 0.25 * sin(t * 2.0)
	var pts := PackedVector2Array()
	for i in 12:
		var ang := PI + i * PI / 11.0
		pts.append(c + Vector2(cos(ang) * 26.0, sin(ang) * 26.0))
	for i in 5:
		var x := 26.0 - i * 13.0
		pts.append(c + Vector2(x, 30.0 + 6.0 * sin(t * 6.0 + i)))
	draw_colored_polygon(pts, Color(0.06, 0.08, 0.14, a))
	pts.append(pts[0])
	draw_polyline(pts, Color(col, a + 0.2), 2.0)
	# Rueda de carga girando.
	var spin := t * 6.0
	draw_arc(c, 12.0, spin, spin + PI * 1.5, 16, col, 3.0)
	if charge > 0.0:
		var k := 1.0 - charge / 0.9
		draw_arc(c + Vector2(facing * 34, -6), 10.0 + 18.0 * k, 0, TAU, 20, Color(col, 0.7), 2.0)
	EnemyKit.label(self, Vector2(0, -70), "sync", 13, Color(col, 0.8))
