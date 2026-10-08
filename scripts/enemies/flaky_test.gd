class_name FlakyTest
extends EnemyBase
## Test Flaky: espectro no determinista. Alterna sin patrón fijo entre FAIL
## (rojo: intangible, los golpes lo atraviesan y se lanza contra ti) y PASS
## (verde: quieto, inofensivo y vulnerable). Espera al verde para golpear.

var passing := true
var timer := 1.5
var home := Vector2.ZERO
var has_home := false


func _setup() -> void:
	enemy_id = "flaky_test"
	max_hp = 3
	bits_drop = 8
	body_size = Vector2(46, 60)
	uses_gravity = false


func _after_setup() -> void:
	contact.set_enabled(false)


func take_hit(hit: Dictionary) -> Dictionary:
	if not passing and not dead:
		EnemyKit.tip("flaky", "Test flaky: en FAIL (rojo) los golpes lo atraviesan. Golpéalo cuando esté en PASS (verde)")
		return {"solid": false, "energy": false, "pogo": false}
	return super.take_hit(hit)


func _ai(delta: float) -> void:
	if not has_home:
		home = global_position
		has_home = true
	timer -= delta
	var tp := to_player()
	if timer <= 0.0:
		passing = not passing
		# Duración aleatoria: el resultado no es reproducible.
		timer = randf_range(1.2, 2.4) if passing else randf_range(1.0, 2.0)
		contact.set_enabled(not passing)
		flash = 0.6
		AudioManager.play_sfx("sello_ok" if passing else "sello_bad", 0.3)
	if passing:
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	elif tp.length() < 520.0:
		velocity = EnemyKit.steer(velocity, global_position, global_position + tp + Vector2(0, -20), 300.0, 900.0, delta)
	else:
		velocity = EnemyKit.steer(velocity, global_position, home, 150.0, 500.0, delta)
	if absf(velocity.x) > 5.0:
		facing = signf(velocity.x)
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -32)
	var col := Color(0.5, 2.4, 0.9) if passing else Color(2.6, 0.5, 0.5)
	var a := 0.95 if passing else 0.45 + 0.2 * sin(t * 25.0)
	var jitter := Vector2.ZERO if passing else Vector2(randf_range(-3, 3), randf_range(-2, 2))
	var pts := PackedVector2Array()
	for i in 10:
		var ang := PI + i * PI / 9.0
		pts.append(c + jitter + Vector2(cos(ang) * 22.0, sin(ang) * 22.0))
	for i in 4:
		pts.append(c + jitter + Vector2(22.0 - i * 14.7, 28.0 + 5.0 * sin(t * 8.0 + i)))
	draw_colored_polygon(pts, Color(0.06, 0.07, 0.08, a))
	pts.append(pts[0])
	draw_polyline(pts, Color(col, a), 2.0)
	var mark := "✓" if passing else "✗"
	EnemyKit.label(self, c + jitter + Vector2(0, 8), mark, 22, Color(col, a))
	EnemyKit.label(self, Vector2(0, -66), "PASS" if passing else "FAIL", 13, Color(col, 0.9))
