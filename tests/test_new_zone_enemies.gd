extends RefCounted
## Enemigos de las zonas 1, 2, 8 y 9: cada uno ataca de verdad (dispara, embiste
## o se lanza contra el jugador) y sus reglas especiales funcionan.

var t
var room: RoomBase
var player: Player

const FLOOR_Y := 17 * 64.0
const SHOOTERS := ["over_fetcher", "render_bloqueante", "framework_obsoleto", "inyeccion_sql",
	"xss_fantasma", "fuga_memoria", "logica_en_vista"]
const MOVERS := ["stateless_drone", "error_500", "lock_pesimista", "acoplamiento_rigido",
	"pod_zombi", "imagen_obsoleta", "daemon_desbocado", "flaky_test", "mutacion_silenciosa"]


func before_each() -> void:
	GameState.new_game()
	room = load("res://tests/fixtures/test_room.gd").new()
	t.add_child(room)
	room.build()
	player = Player.new()
	t.add_child(player)
	player.global_position = Vector2(20 * 64, FLOOR_Y - 2)
	player.invuln = 999.0


func after_each() -> void:
	for n in t.get_tree().get_nodes_in_group("enemy"):
		n.queue_free()
	for c in t.get_children():
		if c is BossAttacks.BossProjectile or c is BossAttacks.Shockwave:
			c.queue_free()
	player.queue_free()
	room.queue_free()


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _spawn(kind: String, offset_x: float, flying: bool) -> EnemyBase:
	var e: EnemyBase = load("res://scripts/enemies/%s.gd" % kind).new()
	e.facing = -1.0
	e.position = Vector2(20 * 64 + offset_x, FLOOR_Y - (150.0 if flying else 2.0))
	t.add_child(e)
	return e


func _projectiles() -> int:
	var n := 0
	for c in t.get_children():
		if c is BossAttacks.BossProjectile or c is BossAttacks.Shockwave:
			n += 1
	return n


func test_los_tiradores_disparan_al_jugador() -> void:
	for kind: String in SHOOTERS:
		var e := _spawn(kind, 340.0, false)
		var flying := not e.uses_gravity
		if flying:
			e.position.y = FLOOR_Y - 150.0
		var before := _projectiles()
		var fired := false
		for i in 720:
			await t.get_tree().physics_frame
			if _projectiles() > before:
				fired = true
				break
		t.ok(fired, "%s dispara cuando ve al jugador" % kind)
		t.ok(is_instance_valid(e) and not e.dead, "%s sigue vivo sin errores" % kind)
		e.queue_free()
		for c in t.get_children():
			if c is BossAttacks.BossProjectile:
				c.queue_free()
		await _frames(2)


func test_los_cuerpo_a_cuerpo_van_a_por_el_jugador() -> void:
	for kind: String in MOVERS:
		var e := _spawn(kind, 300.0, false)
		if not e.uses_gravity:
			e.position.y = FLOOR_Y - 120.0
		await _frames(2)
		var d0 := absf(e.global_position.x - player.global_position.x)
		var closest := d0
		for i in 420:
			await t.get_tree().physics_frame
			if not is_instance_valid(e):
				break
			closest = minf(closest, absf(e.global_position.x - player.global_position.x))
		t.ok(closest < d0 - 60.0 or _projectiles() > 0, "%s ataca o se acerca (%.0f → %.0f px)" % [kind, d0, closest])
		if is_instance_valid(e):
			e.queue_free()
		await _frames(2)


func test_bloqueo_pesimista_solo_cae_por_la_espalda() -> void:
	var e := _spawn("lock_pesimista", 200.0, false)
	await _frames(10)
	e.facing = -1.0
	var hp0 := e.hp
	var r: Dictionary = e.take_hit({"damage": 1, "dir": Vector2.RIGHT, "position": e.global_position + Vector2(-60, 0)})
	t.eq(e.hp, hp0, "de frente no pierde vida")
	t.ok(not r.get("energy", true), "el golpe frontal no da energía")
	e.take_hit({"damage": 1, "dir": Vector2.LEFT, "position": e.global_position + Vector2(60, 0)})
	t.eq(e.hp, hp0 - 1, "por la espalda sí recibe daño")


func test_test_flaky_es_intangible_en_fail() -> void:
	var e := _spawn("flaky_test", 300.0, true)
	await _frames(4)
	e.passing = false
	var hp0 := e.hp
	var r: Dictionary = e.take_hit({"damage": 1, "dir": Vector2.LEFT, "position": e.global_position})
	t.eq(e.hp, hp0, "en FAIL el golpe lo atraviesa")
	t.ok(not r.get("solid", true), "en FAIL no es sólido")
	e.passing = true
	e.take_hit({"damage": 1, "dir": Vector2.LEFT, "position": e.global_position})
	t.eq(e.hp, hp0 - 1, "en PASS recibe daño")


func test_pod_zombi_se_reinicia_una_vez() -> void:
	var e := _spawn("pod_zombi", 400.0, false)
	await _frames(4)
	e.take_hit({"damage": 99, "dir": Vector2.LEFT, "position": e.global_position})
	t.ok(not e.dead, "el primer golpe mortal no lo elimina (Restarting…)")
	await _frames(300)
	t.ok(e.restarted and e.hp > 0, "vuelve con vida tras reiniciarse")
	e.take_hit({"damage": 99, "dir": Vector2.LEFT, "position": e.global_position})
	t.ok(e.dead, "la segunda vez muere de verdad")


func test_reglas_de_framework_imagen_fuga_y_mutante() -> void:
	var f := _spawn("framework_obsoleto", 500.0, false)
	await _frames(4)
	f.take_hit({"damage": 3, "dir": Vector2.LEFT, "position": f.global_position})
	t.ok(f.broken, "el framework pierde la armadura a mitad de vida")
	f.queue_free()
	var img := _spawn("imagen_obsoleta", 500.0, false)
	await _frames(4)
	t.eq(img.layers_left(), 3, "la imagen empieza con 3 capas")
	img.take_hit({"damage": 3, "dir": Vector2.LEFT, "position": img.global_position})
	t.eq(img.layers_left(), 2, "cada 3 de daño cae una capa")
	img.queue_free()
	var fuga := _spawn("fuga_memoria", 300.0, true)
	await _frames(4)
	var size0 := fuga.body_size
	fuga.grow_timer = 0.0
	await _frames(3)
	t.ok(fuga.growth == 1 and fuga.body_size.x > size0.x, "la fuga de memoria crece")
	fuga.queue_free()
	var m := _spawn("mutacion_silenciosa", 300.0, true)
	await _frames(4)
	var op0: int = m.op
	m.take_hit({"damage": 1, "dir": Vector2.LEFT, "position": m.global_position})
	t.ok(m.op != op0, "el mutante cambia de operador al recibir un golpe")
	m.queue_free()
	await _frames(2)
