extends EnemyBase
## Murciélago casi invisible: solo se revela cerca de la luz o del jugador.

var home := Vector2.ZERO
var swoop_t := 0.0
var cooldown := 1.5
var swoop_dir := Vector2.ZERO
var visibility := 0.1


func _setup() -> void:
	enemy_id = "alt_ausente"
	max_hp = 2
	bits_drop = 5
	body_size = Vector2(46, 34)
	uses_gravity = false


func _after_setup() -> void:
	position.y -= 120
	home = position


func _ai(delta: float) -> void:
	cooldown -= delta
	var tp := to_player()
	if swoop_t > 0.0:
		swoop_t -= delta
		velocity = swoop_dir * 420.0
	elif cooldown <= 0.0 and tp.length() < 460.0:
		swoop_t = 1.1
		cooldown = 2.4
		swoop_dir = (tp + Vector2(0, -40)).normalized()
		AudioManager.play_sfx("spit", 0.2)
	else:
		var goal := home + Vector2(sin(t * 0.9) * 90.0, sin(t * 1.7) * 30.0)
		velocity = (goal - position) * 2.0
	facing = signf(velocity.x) if absf(velocity.x) > 5.0 else facing
	var coll := move_and_collide(velocity * delta)
	if coll:
		swoop_t = 0.0
	# Visibilidad.
	var target_vis := 0.08
	if tp.length() < 190.0 or swoop_t > 0.0:
		target_vis = 0.85
	for l in get_tree().get_nodes_in_group("light_source"):
		if l.energy > 0.3 and l.global_position.distance_to(global_position) < 260.0:
			target_vis = 1.0
			break
	visibility = lerpf(visibility, target_vis, 1.0 - exp(-6.0 * delta))
	modulate.a = visibility


func _draw_body() -> void:
	var c := Vector2(0, -18)
	var flap := sin(t * 14.0)
	var dark := Color(0.05, 0.05, 0.08)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			c, c + Vector2(side * 26, -14 - flap * 10), c + Vector2(side * 52, -4 - flap * 16),
			c + Vector2(side * 40, 8), c + Vector2(side * 30, 2), c + Vector2(side * 18, 10)])
		draw_colored_polygon(wing, dark)
	draw_circle(c, 14, dark)
	# Marco de imagen vacío (sin alt).
	draw_rect(Rect2(c + Vector2(-9, -8), Vector2(18, 14)), Color(0.6, 0.6, 0.7, 0.7), false, 2.0)
	draw_line(c + Vector2(-9, 6), c + Vector2(9, -8), Color(0.6, 0.6, 0.7, 0.7), 1.5)
	eye(c + Vector2(-5, 10), 2.5, Color(2.6, 2.6, 2.8))
	eye(c + Vector2(5, 10), 2.5, Color(2.6, 2.6, 2.8))
