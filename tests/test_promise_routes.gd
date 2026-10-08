extends RefCounted
## Bots de la zona 5: canales, puzles de promesas (cumplir, .then, .catch,
## Promise.all) y la cadena de la arena de Callback Hell.

var t
var room: RoomBase
var player: Player

const TILE := 64.0


func _setup(room_id: String, start_tile: Vector2) -> void:
	GameState.new_game()
	GameState.grant_ability("promesa")
	room = load("res://rooms/%s.gd" % room_id).new()
	room.room_id = room_id
	t.add_child(room)
	room.build()
	player = Player.new()
	t.add_child(player)
	player.place_at(start_tile * TILE)
	await t.get_tree().process_frame
	for e in t.get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	await _frames(30)


func after_each() -> void:
	for a in ["move_left", "move_right", "jump"]:
		Input.action_release(a)
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _seconds(s: float) -> void:
	await _frames(int(s * Engine.physics_ticks_per_second))


func _tile() -> Vector2:
	return player.global_position / TILE


func _fountain(id: String) -> Node:
	return room.get_entity(id)


## Salta hacia una x objetivo manteniendo la dirección hasta llegar.
func _jump_toward(target_x: float) -> void:
	var dir := "move_right" if target_x > _tile().x else "move_left"
	Input.action_press("jump")
	Input.action_press(dir)
	for i in 70:
		await t.get_tree().physics_frame
		if absf(_tile().x - target_x) < 0.25:
			Input.action_release(dir)
		if i == 38:
			Input.action_release("jump")
		if i > 12 and player.is_on_floor():
			break
	Input.action_release(dir)
	Input.action_release("jump")
	await _frames(14)


func _run_and_hop(dir: String, frames: int) -> void:
	Input.action_press(dir)
	var hold := 0
	var sign := 1.0 if dir == "move_right" else -1.0
	for i in frames:
		await t.get_tree().physics_frame
		if hold > 0:
			hold -= 1
			if hold == 0:
				Input.action_release("jump")
		elif player.is_on_floor() and (_edge_ahead(sign) or _wall_ahead(sign) or _hazard_ahead(sign)):
			Input.action_press("jump")
			hold = 40
	Input.action_release("jump")
	Input.action_release(dir)
	await _frames(40)


func _edge_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(sign * 30.0, -6)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), 1)
	return space.intersect_ray(q).is_empty()


func _wall_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(0, -20)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(sign * 44.0, 0), 1)
	return not space.intersect_ray(q).is_empty()


func _hazard_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var q := PhysicsPointQueryParameters2D.new()
	q.position = player.global_position + Vector2(sign * 56.0, -12)
	q.collision_mask = 1 << 6
	q.collide_with_areas = true
	q.collide_with_bodies = false
	return not space.intersect_point(q, 1).is_empty()


# --- Estados de una fuente -------------------------------------------------------

func test_fountain_states_and_timeout_charm() -> void:
	await _setup("z5_manantial", Vector2(26.0, 20.9))
	var f = _fountain("manantial")
	t.eq(f.state, "idle", "empieza en idle")
	t.ok(f.trigger(), "se activa")
	t.eq(f.state, "pending", "pasa a pending")
	t.ok(not f.trigger(), "no se reactiva mientras está en curso")
	await _seconds(1.35)
	t.eq(f.state, "fulfilled", "se cumple tras el retardo")
	t.ok(not f.platforms[0].get_child(0).disabled, "plataformas sólidas al cumplirse")
	await _seconds(5.2)
	t.eq(f.state, "idle", "vuelve a idle al terminar la duración")
	await _frames(2)
	t.ok(f.platforms[0].get_child(0).disabled, "plataformas desactivadas")
	t.eq(f.fulfilled_duration(), 5.0, "duración normal")
	GameState.grant_charm("timeout")
	t.ok(GameState.equip_charm("timeout", 1), "equipa Timeout")
	t.ok(f.fulfilled_duration() > 7.9, "Timeout alarga la duración")


func test_manantial_canal_needs_promise() -> void:
	await _setup("z5_manantial", Vector2(27.5, 20.9))
	await _run_and_hop("move_right", 160)
	var p := _tile()
	t.ok(not (p.x > 38.0 and GameState.data.masks == 5), "sin la promesa no se cruza sin daño (%.1f)" % p.x)


func test_manantial_canal_with_promise() -> void:
	await _setup("z5_manantial", Vector2(27.5, 20.9))
	_fountain("manantial").trigger()
	await _seconds(1.35)
	await _run_and_hop("move_right", 200)
	var p := _tile()
	print("  manantial canal: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 38.0 and p.y < 21.2, "cruza el canal (%.1f, %.1f)" % [p.x, p.y])
	t.eq(GameState.data.masks, 5, "sin caer al agua")


func test_manantial_then_chain_to_charm_ledge() -> void:
	await _setup("z5_manantial", Vector2(46.5, 20.9))
	_fountain("cornisa").trigger()
	await _seconds(1.1)
	await _jump_toward(48.8)      # plataforma 1 (fila 19)
	await _seconds(0.8)
	t.eq(_fountain("cornisa_b").state, "fulfilled", ".then activó la segunda fuente")
	await _jump_toward(51.6)      # plataforma 2 (fila 17)
	await _jump_toward(54.0)      # cornisa (fila 15)
	var p := _tile()
	print("  manantial cornisa: ", p)
	t.ok(p.y < 15.2 and p.x > 52.8, "llega a la cornisa del amuleto (%.1f, %.1f)" % [p.x, p.y])


func test_delta_then_chain_climb() -> void:
	await _setup("z5_delta", Vector2(22.5, 22.9))
	_fountain("api1").trigger()
	await _seconds(1.3)
	await _jump_toward(25.0)      # api1 (fila 21)
	await _seconds(0.6)
	await _jump_toward(22.0)      # api2 (fila 19)
	await _seconds(0.6)
	await _jump_toward(25.0)      # api3 (fila 17)
	await _seconds(0.6)
	await _jump_toward(28.0)      # api4 (fila 15)
	await _jump_toward(31.5)      # meseta (fila 13)
	var p := _tile()
	print("  delta cadena: ", p)
	t.ok(p.y < 13.2 and p.x > 30.0, "sube a la meseta encadenando promesas (%.1f, %.1f)" % [p.x, p.y])


func test_aduana_rejection_opens_catch_route() -> void:
	await _setup("z5_aduana", Vector2(24.0, 18.9))
	var q = _fountain("otro_origen")
	q.trigger()
	await _seconds(1.3)
	t.eq(q.state, "rejected", "la petición a otro origen se rechaza")
	t.eq(_fountain("respaldo").state, "pending", ".catch activa la ruta de respaldo")
	await _seconds(0.9)
	await _run_and_hop("move_right", 220)
	var p := _tile()
	print("  aduana catch: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 37.5 and p.y < 19.2, "cruza por las plataformas del catch (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin caer al agua")


func test_observatorio_promise_all_gate() -> void:
	await _setup("z5_observatorio", Vector2(30.0, 18.9))
	var gate = room.get_entity("compuerta_all")
	_fountain("peticion_a").trigger()
	await _seconds(1.4)
	t.ok(not gate.is_open(), "una sola promesa no abre Promise.all")
	_fountain("peticion_b").trigger()
	await _seconds(2.4)
	t.ok(gate.is_open(), "con ambas cumplidas se abre")
	await _seconds(7.5)
	t.ok(gate.is_open(), "queda abierta al terminar las promesas")


func test_observatorio_fountains_reachable_in_time() -> void:
	await _setup("z5_observatorio", Vector2(31.0, 18.9))
	_fountain("peticion_a").trigger()
	var frames := 0
	Input.action_press("move_right")
	while _tile().x < 50.6 and frames < 600:
		await t.get_tree().physics_frame
		frames += 1
	Input.action_release("move_right")
	var secs := float(frames) / Engine.physics_ticks_per_second
	print("  observatorio a→b: %.2f s" % secs)
	t.ok(secs + 1.2 < 7.0, "da tiempo a activar la segunda antes de que expire la primera (%.2f s)" % secs)


func test_arena_chain_reaches_boss_height() -> void:
	await _setup("z5_arena", Vector2(7.5, 18.9))
	_fountain("cadena1").trigger()
	await _seconds(1.1)
	await _jump_toward(10.5)      # fila 17
	await _seconds(0.5)
	await _jump_toward(15.0)      # fila 15
	await _seconds(0.3)
	Input.action_press("move_right")
	while _tile().x < 16.5:
		await t.get_tree().physics_frame
	Input.action_release("move_right")
	await _jump_toward(19.2)      # fila 13
	var p := _tile()
	print("  arena cadena: ", p)
	t.ok(p.y < 13.2 and p.x > 17.8, "llega a la plataforma alta (%.1f, %.1f)" % [p.x, p.y])
	var floor_px := 19.0 * TILE
	t.ok(floor_px - player.global_position.y + 185.0 > CallbackHell.PERCH_H - 90.0, "desde ahí el salto alcanza al jefe elevado")


func test_right_arena_chain_links_to_top() -> void:
	await _setup("z5_arena", Vector2(34.5, 18.9))
	_fountain("cadena4").trigger()
	await _seconds(1.1)
	t.eq(_fountain("cadena4").state, "fulfilled", "cadena derecha activa")
	await _seconds(1.0)
	t.eq(_fountain("cadena5").state, "fulfilled", ".then encadena cadena5")
	await _seconds(1.0)
	t.eq(_fountain("cadena3").state, "fulfilled", "cadena5 enlaza con la plataforma alta")


# --- Rutas sin habilidad ---------------------------------------------------------

func test_embarcadero_canal() -> void:
	await _setup("z5_embarcadero", Vector2(27.0, 16.9))
	await _run_and_hop("move_right", 200)
	var p := _tile()
	t.ok(p.x > 34.0, "cruza el canal del embarcadero (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin caer al agua")


func test_esclusas_route() -> void:
	await _setup("z5_esclusas", Vector2(9.0, 18.9))
	await _run_and_hop("move_right", 900)
	var p := _tile()
	print("  esclusas: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 46.0, "recorre las esclusas hasta el sello (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin caer al agua")


func test_compuerta_route() -> void:
	await _setup("z5_compuerta", Vector2(12.0, 18.9))
	await _run_and_hop("move_right", 700)
	var p := _tile()
	print("  compuerta: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 36.0, "supera el muro y el canal (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin caer al agua")
