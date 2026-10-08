class_name OverFetcher
extends EnemyBase
## Sobrecarga de Payload: flota pesado siguiendo al jugador y dispara abanicos
## de 3 proyectiles de datos (pide mucho más de lo que necesita).

var shoot_timer := 2.2
var windup := 0.0
var home_y := 0.0
var has_home := false


func _setup() -> void:
	enemy_id = "over_fetcher"
	max_hp = 5
	bits_drop = 10
	body_size = Vector2(56, 56)
	uses_gravity = false
	knock_resist = 0.4


func _ai(delta: float) -> void:
	if not has_home:
		home_y = global_position.y
		has_home = true
	var tp := to_player()
	var near := tp.length() < 620.0
	shoot_timer -= delta
	if windup > 0.0:
		windup -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		if windup <= 0.0:
			var from := global_position + Vector2(0, -28)
			EnemyKit.fan(self, from, global_position + tp + Vector2(0, -40), 340.0, 3, 0.28, "{…}")
			shoot_timer = 2.8
	else:
		var drift := sin(t * 0.7) * 40.0
		if near and absf(tp.x) > 200.0:
			drift = signf(tp.x) * 60.0
		var goal := Vector2(global_position.x + drift, home_y + sin(t * 2.0) * 18.0)
		velocity = EnemyKit.steer(velocity, global_position, goal, 90.0, 400.0, delta)
		if near and tp.x != 0.0:
			facing = signf(tp.x)
		if near and shoot_timer <= 0.0:
			windup = 0.55
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -28)
	var col := Color(1.8, 0.8, 2.2)
	var puff := 1.0 + 0.04 * sin(t * 3.0)
	if windup > 0.0:
		puff = 1.0 + 0.12 * sin(t * 30.0)
	draw_circle(c, 34.0 * puff, Color(col, 0.1))
	draw_circle(c, 26.0 * puff, Color(0.1, 0.05, 0.12))
	draw_arc(c, 26.0 * puff, 0.0, TAU, 28, col, 2.5)
	# Campos que sobran orbitando alrededor.
	for i in 5:
		var a := t * 1.5 + i * TAU / 5.0
		draw_circle(c + Vector2.RIGHT.rotated(a) * 36.0, 4.0, Color(col, 0.7))
	eye(c + Vector2(facing * 9, -4), 5.0, Color(2.4, 0.6, 1.8))
	EnemyKit.label(self, Vector2(0, -66), "SELECT *", 13, Color(col, 0.85))
