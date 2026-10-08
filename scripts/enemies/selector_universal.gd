extends EnemyBase
## Araña `*`: cuelga del techo, cae sobre el jugador y ataca en área.

enum S { HANG, DROP, TELEGRAPH, BURST, RECOVER, CLIMB }

var s := S.HANG
var ceiling_y := 0.0
var hang_y := 0.0
var timer := 0.0
var burst_area: DamageArea
const RADIUS := 150.0


func _setup() -> void:
	enemy_id = "selector_universal"
	max_hp = 4
	bits_drop = 6
	body_size = Vector2(52, 44)
	uses_gravity = false


func _after_setup() -> void:
	burst_area = DamageArea.new()
	var c := CircleShape2D.new()
	c.radius = RADIUS
	burst_area.add_shape(c, Vector2(0, -22))
	burst_area.set_enabled(false)
	add_child(burst_area)
	# Buscar el techo sobre la posición inicial.
	await get_tree().physics_frame
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -10), global_position + Vector2(0, -1600), 1)
	var hit := space.intersect_ray(q)
	ceiling_y = hit.position.y if not hit.is_empty() else global_position.y - 400
	hang_y = ceiling_y + 120
	global_position.y = hang_y


func _ai(delta: float) -> void:
	timer -= delta
	match s:
		S.HANG:
			velocity = Vector2.ZERO
			global_position.y = move_toward(global_position.y, hang_y + sin(t * 1.5) * 8.0, 200 * delta)
			var tp := to_player()
			if absf(tp.x) < 130.0 and tp.y > 0.0 and tp.y < 900.0:
				s = S.DROP
		S.DROP:
			velocity = Vector2(0, 1000)
			move_and_slide()
			if is_on_floor():
				s = S.TELEGRAPH
				timer = 0.45
				Events.camera_shake.emit(6.0, 0.2)
				FX.dust(get_parent(), global_position, 10)
				AudioManager.play_sfx("land")
		S.TELEGRAPH:
			if timer <= 0.0:
				s = S.BURST
				timer = 0.16
				burst_area.set_enabled(true)
				AudioManager.play_sfx("slash")
				FX.burst(get_parent(), global_position + Vector2(0, -22), Color(2.4, 0.5, 1.8), 30, 700.0, 0.35, 0.35, Vector2.ZERO)
		S.BURST:
			if timer <= 0.0:
				burst_area.set_enabled(false)
				s = S.RECOVER
				timer = 0.9
		S.RECOVER:
			if timer <= 0.0:
				s = S.CLIMB
		S.CLIMB:
			global_position.y = move_toward(global_position.y, hang_y, 320 * delta)
			if absf(global_position.y - hang_y) < 2.0:
				s = S.HANG


func _draw_body() -> void:
	var dark := Color(0.05, 0.03, 0.06)
	var body_c := Vector2(0, -22)
	# Hilo al techo.
	if s != S.DROP or true:
		draw_line(body_c, Vector2(0, ceiling_y - global_position.y), Color(0.5, 0.5, 0.6, 0.35), 1.5)
	# Patas.
	for i in 4:
		for side in [-1.0, 1.0]:
			var a := 0.4 + i * 0.35
			var knee := body_c + Vector2(side * (24 + i * 4), -14 + i * 6 + sin(t * 6 + i) * 3)
			var foot := knee + Vector2(side * 16, 22 + i * 2)
			draw_polyline(PackedVector2Array([body_c, knee, foot]), dark, 3.0, true)
	draw_circle(body_c, 24, dark)
	# Asterisco brillante.
	var glow := Color(2.4, 0.5, 1.8)
	if s == S.TELEGRAPH:
		var k := 1.0 - timer / 0.45
		draw_arc(body_c, RADIUS * k, 0, TAU, 48, Color(2.4, 0.4, 1.6, 0.6), 3.0, true)
		glow = Color(3.0, 1.2, 2.4)
	for i in 3:
		var a := PI * i / 3.0 + (t * 3.0 if s == S.TELEGRAPH else 0.0)
		draw_line(body_c + Vector2(cos(a), sin(a)) * 12, body_c - Vector2(cos(a), sin(a)) * 12, glow, 4.0, true)
	eye(body_c + Vector2(-8, 12), 2.5)
	eye(body_c + Vector2(8, 12), 2.5)
