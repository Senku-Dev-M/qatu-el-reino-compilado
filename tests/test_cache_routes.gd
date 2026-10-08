extends RefCounted
## Bots de la zona 6: habilidad Caché, estanterías paginadas y compuertas
## temporizadas que solo se superan guardando y restaurando la caché.

var t
var room: RoomBase
var player: Player

const TILE := 64.0


func _setup(room_id: String, start_tile: Vector2) -> void:
	GameState.new_game()
	GameState.grant_ability("cache")
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
	await _frames(12)


## Camina hasta una x (saltando si hay borde o foso delante). Devuelve los segundos empleados.
func _run_to(target_x: float, max_frames := 600) -> float:
	var dir := "move_right" if target_x > _tile().x else "move_left"
	var sign := 1.0 if dir == "move_right" else -1.0
	Input.action_press(dir)
	var hold := 0
	var frames := 0
	while (_tile().x - target_x) * sign < 0.0 and frames < max_frames:
		await t.get_tree().physics_frame
		frames += 1
		if hold > 0:
			hold -= 1
			if hold == 0:
				Input.action_release("jump")
		elif player.is_on_floor() and _edge_ahead(sign):
			Input.action_press("jump")
			hold = 36
	Input.action_release(dir)
	Input.action_release("jump")
	await _frames(12)
	return float(frames) / Engine.physics_ticks_per_second


func _edge_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(sign * 30.0, -6)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), 1)
	return space.intersect_ray(q).is_empty()


# --- Habilidad Caché ----------------------------------------------------------------

func test_cache_store_restore_and_ttl() -> void:
	await _setup("z6_catalogo", Vector2(30.0, 18.9))
	var start := player.global_position
	t.ok(player.cache_store(), "guarda la caché en el suelo")
	t.ok(player.has_cache(), "hay caché")
	await _run_to(24.0)
	t.ok(player.global_position.distance_to(start) > TILE * 4, "el jugador se alejó")
	t.ok(player.cache_restore(), "restaura")
	t.ok(player.global_position.distance_to(start) < 2.0, "vuelve a la posición guardada")
	t.ok(not player.has_cache(), "restaurar consume la caché")
	t.ok(not player.cache_restore(), "sin caché no hay restauración")
	player.cache_store()
	await _seconds(player.CACHE_TTL + 0.3)
	t.ok(not player.has_cache(), "caduca al pasar el TTL")
	player.cache_store()
	player.place_at(start)
	t.ok(not player.has_cache(), "cambiar de posición por código (cambio de sala) invalida la caché")
	GameState.grant_charm("cdn")
	GameState.equip_charm("cdn", 2)
	t.eq(player.cache_ttl_max(), player.CACHE_TTL * 2.0, "el amuleto CDN duplica el TTL")


func test_cache_needs_floor() -> void:
	await _setup("z6_catalogo", Vector2(30.0, 18.9))
	Input.action_press("jump")
	await _frames(10)
	t.ok(not player.is_on_floor(), "en el aire")
	t.ok(not player.cache_store(), "no se guarda en el aire")
	Input.action_release("jump")


func test_gzip_reduces_heal_cost() -> void:
	GameState.new_game()
	var base := GameState.heal_cost()
	GameState.grant_charm("gzip")
	GameState.equip_charm("gzip", 1)
	t.ok(GameState.heal_cost() < base * 0.7, "gzip abarata el Hotfix")


# --- Paginadores ----------------------------------------------------------------------

func test_paginator_pages_and_queries() -> void:
	await _setup("z6_estanteria", Vector2(10.0, 22.9))
	var pg = room.get_entity("estantes")
	t.eq(pg.page_count(), 3, "9 baldas de 3 en 3 son 3 páginas")
	t.eq(pg.items_on_page(2), [3, 4, 5], "página 2")
	t.eq(pg.query_text(3), "GET /estantes?$top=3&$skip=6", "consulta OData")
	pg.set_page(2, false)
	await _frames(2)
	t.ok(pg.bodies[0].get_child(0).disabled, "las baldas de la página 1 desaparecen")
	t.ok(not pg.bodies[4].get_child(0).disabled, "las de la página 2 existen")
	pg.next_page()
	t.eq(pg.page, 3, "siguiente")
	pg.next_page()
	t.eq(pg.page, 1, "vuelve a la primera")
	pg.previous_page()
	t.eq(pg.page, 3, "anterior desde la primera va a la última")


func test_jsonapi_query_text() -> void:
	await _setup("z6_galeria", Vector2(10.0, 18.9))
	var pg = room.get_entity("galeria")
	t.eq(pg.query_text(2), "GET /cuadros?page[number]=2&page[size]=3", "consulta JSON:API")


func test_estanteria_paginated_climb() -> void:
	await _setup("z6_estanteria", Vector2(21.0, 22.9))
	await _jump_toward(22.8)      # balda 1 (fila 21)
	await _jump_toward(25.6)      # balda 2 (fila 19)
	await _jump_toward(28.6)      # balda 3 (fila 17)
	await _jump_toward(31.8)      # pilar A (fila 15)
	t.ok(_tile().y < 15.2, "llega al pilar A (%.1f, %.1f)" % [_tile().x, _tile().y])
	room.get_entity("atril_2").interact(player)
	await _frames(4)
	await _run_to(34.3)
	await _jump_toward(36.6)      # balda 4 (fila 13)
	await _jump_toward(39.6)      # balda 5 (fila 11)
	await _jump_toward(42.6)      # balda 6 (fila 9)
	await _jump_toward(46.2)      # pilar B (fila 7)
	t.ok(_tile().y < 7.2, "llega al pilar B (%.1f, %.1f)" % [_tile().x, _tile().y])
	room.get_entity("atril_3").interact(player)
	await _frames(4)
	await _run_to(48.2)
	await _jump_toward(50.6)
	await _jump_toward(53.6)
	await _jump_toward(56.8)
	await _run_to(57.4, 60)
	var p := _tile()
	print("  estantería: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 56.6 and p.y < 7.2, "llega a la cornisa del sello de salida (%.1f, %.1f)" % [p.x, p.y])
	t.eq(GameState.data.masks, 5, "sin caer en la tinta")


func test_estanteria_needs_next_page() -> void:
	await _setup("z6_estanteria", Vector2(34.4, 14.9))
	await _jump_toward(36.6)
	t.ok(_tile().y > 15.5, "sin pedir la página 2 no hay balda (%.1f)" % _tile().y)


func test_galeria_paginated_bridge() -> void:
	await _setup("z6_galeria", Vector2(18.5, 18.9))
	await _run_to(31.0)
	t.eq(GameState.data.masks, 5, "cruza el primer foso con la página 1")
	room.get_entity("atril_2").interact(player)
	await _frames(4)
	await _run_to(44.0)
	room.get_entity("atril_3").interact(player)
	await _frames(4)
	await _run_to(57.0)
	var p := _tile()
	print("  galería: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 56.5 and p.y < 19.2, "cruza los tres fosos (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin tocar los pinchos")


func test_galeria_blocked_without_page() -> void:
	await _setup("z6_galeria", Vector2(31.0, 18.9))
	await _run_to(44.0, 180)
	t.ok(GameState.data.masks < 5 or _tile().x < 43.0, "sin la página 2 no se cruza el segundo foso")


# --- Compuertas temporizadas ---------------------------------------------------------

func test_sotano_gate_needs_cache() -> void:
	await _setup("z6_sotano", Vector2(22.5, 18.9))
	room.get_entity("palanca_sotano").pull()
	var secs := await _run_to(41.0, 300)
	print("  sótano sin caché: %.2f s, x=%.1f" % [secs, _tile().x])
	t.ok(_tile().x < 40.2, "corriendo no se llega antes de que cierre (%.1f)" % _tile().x)


func test_sotano_gate_with_cache() -> void:
	await _setup("z6_sotano", Vector2(39.3, 18.9))
	t.ok(player.cache_store(), "guarda la caché junto a la compuerta")
	var back := await _run_to(22.5)
	print("  sótano vuelta a la palanca: %.2f s" % back)
	t.ok(player.has_cache(), "la caché sigue vigente al llegar a la palanca")
	room.get_entity("palanca_sotano").pull()
	player.cache_restore()
	await _run_to(42.0, 120)
	t.ok(_tile().x > 41.0, "cruza la compuerta tras restaurar (%.1f)" % _tile().x)


func test_catalogo_fragment_with_cache() -> void:
	await _setup("z6_catalogo", Vector2(36.0, 18.9))
	await _jump_toward(38.2)      # escalón (fila 17)
	await _jump_toward(41.3)      # repisa de la cámara (fila 15)
	t.ok(_tile().y < 15.2, "llega a la repisa (%.1f, %.1f)" % [_tile().x, _tile().y])
	t.ok(player.cache_store(), "guarda la caché junto a la compuerta")
	await _run_to(26.5)
	t.ok(player.has_cache(), "la caché sigue vigente")
	room.get_entity("palanca_catalogo").pull()
	player.cache_restore()
	await _run_to(45.0, 120)
	t.ok(_tile().x > 44.0, "entra en la cámara del fragmento (%.1f)" % _tile().x)


func test_boveda_climb_and_gate() -> void:
	await _setup("z6_boveda", Vector2(25.0, 20.9))
	for x in [27.0, 30.0, 33.0, 36.0, 38.6, 41.0]:
		await _jump_toward(x)
	t.ok(_tile().y < 9.2, "sube a la pasarela (%.1f, %.1f)" % [_tile().x, _tile().y])
	await _run_to(49.3)
	t.ok(player.cache_store(), "guarda la caché junto a la compuerta")
	await _run_to(41.5)            # cae de la pasarela y llega a la palanca
	t.ok(player.has_cache(), "la caché sigue vigente al llegar a la palanca (%.1f, %.1f)" % [_tile().x, _tile().y])
	room.get_entity("palanca_boveda").pull()
	player.cache_restore()
	await _run_to(52.0, 120)
	t.ok(_tile().x > 51.0 and _tile().y < 9.2, "cruza la compuerta alta (%.1f)" % _tile().x)


func test_pasillo_controller_gate_needs_cache() -> void:
	await _setup("z6_pasillo", Vector2(36.5, 18.9))
	room.get_entity("palanca_ctrl").pull()
	await _run_to(51.0, 240)
	t.ok(_tile().x < 50.2, "sin caché no llega (%.1f)" % _tile().x)


func test_pasillo_middleware_chain() -> void:
	await _setup("z6_pasillo", Vector2(12.0, 18.9))
	await _run_to(17.5, 120)
	t.ok(_tile().x < 16.0, "la compuerta de autenticación bloquea")
	room.get_entity("palanca_auth").pull()
	await _seconds(0.8)
	await _run_to(24.0)
	t.ok(_tile().x > 23.0, "next(): pasa la autenticación")
	room.get_entity("palanca_log").pull()
	await _seconds(0.8)
	await _run_to(49.3)
	t.ok(player.cache_store(), "guarda la caché ante el controlador")
	await _run_to(36.6)
	room.get_entity("palanca_ctrl").pull()
	player.cache_restore()
	await _run_to(52.0, 120)
	t.ok(_tile().x > 51.0, "llega al controlador (%.1f)" % _tile().x)
