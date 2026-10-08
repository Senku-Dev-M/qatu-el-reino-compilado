class_name LockPesimista
extends EnemyBase
## Bloqueo Pesimista: guardián con cerrojo frontal. De frente no hay forma de
## dañarlo (el recurso está bloqueado); hay que pasar a su espalda con REST Dash
## o golpearlo desde arriba. Si te acercas de frente, empuja con el cerrojo.

var shield_flash := 0.0
var turn_timer := 0.0
var bash := -2.0


func _setup() -> void:
	enemy_id = "lock_pesimista"
	max_hp = 5
	bits_drop = 10
	body_size = Vector2(60, 84)
	knock_resist = 0.75


func take_hit(hit: Dictionary) -> Dictionary:
	var dir: Vector2 = hit.get("dir", Vector2.ZERO)
	var src: Vector2 = hit.get("position", global_position)
	var from_front := dir.y == 0.0 and signf(src.x - global_position.x) == facing
	if from_front and not dead:
		shield_flash = 1.0
		AudioManager.play_sfx("sello_bad", 0.2)
		FX.burst(get_parent(), global_position + Vector2(facing * 34, -50), Color(2.4, 1.8, 0.6), 8, 280.0, 0.3, 0.3, Vector2.ZERO)
		EnemyKit.tip("lock", "Bloqueo pesimista: de frente no cede. Cruza a su espalda con REST Dash [%s] o atácalo desde arriba" % Settings.key_name("dash"))
		return {"solid": true, "energy": false, "pogo": false}
	return super.take_hit(hit)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	shield_flash = maxf(0.0, shield_flash - delta * 3.0)
	turn_timer -= delta
	bash -= delta
	var tp := to_player()
	if absf(tp.x) < 520.0 and absf(tp.y) < 200.0 and turn_timer <= 0.0 and tp.x != 0.0:
		var want := signf(tp.x)
		if want != facing:
			facing = want
			turn_timer = 1.3  # tarda en girar: es la ventana para flanquearlo
	if bash > 0.0:
		velocity.x = facing * 420.0
	elif absf(tp.x) < 150.0 and absf(tp.y) < 90.0 and signf(tp.x) == facing and bash < -1.2:
		bash = 0.22
		AudioManager.play_sfx("spit", 0.1)
	else:
		if is_on_floor() and (is_wall_ahead() or is_edge_ahead()):
			facing = -facing
			turn_timer = 1.3
		velocity.x = facing * 55.0
	if is_on_floor() and is_edge_ahead():
		velocity.x = 0.0
	move_and_slide()


func _draw_body() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var dark := Color(0.1, 0.09, 0.08)
	var step := sin(t * 5.0) * 3.0
	draw_line(Vector2(-12, -22), Vector2(-14 + step, 0), dark, 10.0)
	draw_line(Vector2(12, -22), Vector2(10 - step, 0), dark, 10.0)
	draw_rect(Rect2(-24, -84, 48, 64), dark)
	draw_rect(Rect2(-24, -84, 48, 64), Color(0.55, 0.5, 0.35), false, 2.0)
	eye(Vector2(8, -70), 3.5, Color(2.4, 1.6, 0.5))
	# Espalda descubierta: la zona vulnerable brilla.
	draw_rect(Rect2(-26, -76, 6, 44), Color(0.6, 2.0, 1.0, 0.35 + 0.25 * sin(t * 4.0)))
	# Cerrojo frontal (escudo).
	var push := 10.0 if bash > 0.0 else 0.0
	var sc := Color(2.2, 1.7, 0.5).lerp(Color(3, 3, 3), shield_flash)
	var sh := Rect2(24 + push, -92, 20, 82)
	draw_rect(sh, Color(0.22, 0.18, 0.08))
	draw_rect(sh, sc, false, 3.0)
	draw_arc(Vector2(34 + push, -58), 7.0, PI, TAU, 10, sc, 3.0)
	draw_rect(Rect2(28 + push, -58, 12, 12), sc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	EnemyKit.label(self, Vector2(0, -102), "LOCK", 16, Color(2.4, 1.7, 0.5, 0.9))
