extends RefCounted
## Un "bot" recorre los tramos obligatorios que requieren el Event Listener
## para comprobar que las cadenas de nodos son superables.

var t
var room: RoomBase
var player: Player

const TILE := 64.0


func _setup(room_id: String, start_tile: Vector2) -> void:
	GameState.new_game()
	GameState.grant_ability("event_listener")
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
	for a in ["move_left", "move_right", "jump", "grapple"]:
		Input.action_release(a)
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


## Engancharse al nodo que el jugador tenga como objetivo y saltar al soltar.
func _grapple_hop(dir: String) -> void:
	Input.action_press(dir)
	await _frames(3)
	await _tap("grapple")
	var guard := 0
	while player.state == Player.State.GRAPPLE and guard < 90:
		await t.get_tree().physics_frame
		guard += 1
	Input.action_press("jump")
	await _frames(24)
	Input.action_release("jump")
	await _frames(20)
	Input.action_release(dir)


func _tile() -> Vector2:
	return player.global_position / TILE


func test_tronco_route_reaches_exit_ledge() -> void:
	await _setup("z3_tronco", Vector2(28.5, 16.9))
	for i in 3:
		await _grapple_hop("move_right")
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	await _frames(20)
	var p := _tile()
	print("  tronco: jugador en ", p)
	t.ok(p.y < 6.2 and p.x > 39.5, "alcanza la cornisa de salida (%.1f, %.1f)" % [p.x, p.y])


func test_copa_l2_to_l3() -> void:
	await _setup("z3_copa", Vector2(13.0, 29.9))
	await _grapple_hop("move_left")
	await _grapple_hop("move_left")
	Input.action_press("move_left")
	await _frames(40)
	Input.action_release("move_left")
	await _frames(30)
	var p := _tile()
	print("  copa L2→L3: ", p)
	t.ok(p.y < 21.2 and p.x < 11.0, "llega a L3 (%.1f, %.1f)" % [p.x, p.y])


func test_copa_l3_to_l4() -> void:
	await _setup("z3_copa", Vector2(9.5, 20.9))
	await _grapple_hop("move_right")
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	await _frames(30)
	var p := _tile()
	print("  copa L3→L4: ", p)
	t.ok(p.y < 15.2 and p.x > 13.5, "llega a L4 (%.1f, %.1f)" % [p.x, p.y])


func test_copa_l4_to_l5() -> void:
	await _setup("z3_copa", Vector2(27.2, 14.9))
	await _grapple_hop("move_right")
	await _frames(30)
	var p := _tile()
	print("  copa L4→L5: ", p)
	t.ok(p.y < 9.2, "llega a L5 (%.1f, %.1f)" % [p.x, p.y])


func test_copa_floor_to_l1() -> void:
	await _setup("z3_copa", Vector2(21.0, 41.9))
	await _grapple_hop("move_right")
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	await _frames(30)
	var p := _tile()
	print("  copa suelo→L1: ", p)
	t.ok(p.y < 38.2 and p.x > 25.5, "llega a L1 (%.1f, %.1f)" % [p.x, p.y])


## Mantiene una dirección y salta (con salto completo) al llegar a un borde
## o a una pared, como haría un jugador.
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


func _jump_up() -> void:
	Input.action_press("jump")
	await _frames(40)
	Input.action_release("jump")
	await _frames(40)


func _walk_to(x_tile: float) -> void:
	var dir := "move_left" if player.global_position.x / TILE > x_tile else "move_right"
	Input.action_press(dir)
	var guard := 0
	while absf(player.global_position.x / TILE - x_tile) > 0.3 and guard < 120:
		await t.get_tree().physics_frame
		guard += 1
	Input.action_release(dir)
	await _frames(10)


func _edge_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(sign * 30.0, -6)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), 1)
	return space.intersect_ray(q).is_empty()


func _hazard_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var q := PhysicsPointQueryParameters2D.new()
	q.position = player.global_position + Vector2(sign * 56.0, -12)
	q.collision_mask = 1 << 6
	q.collide_with_areas = true
	q.collide_with_bodies = false
	return not space.intersect_point(q, 1).is_empty()


func _wall_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(0, -20)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(sign * 44.0, 0), 1)
	return not space.intersect_ray(q).is_empty()


func test_galeria_pit_is_crossable() -> void:
	await _setup("z3_galeria", Vector2(19.0, 16.9))
	await _run_and_hop("move_right", 220)
	var p := _tile()
	print("  galería foso: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 32.0, "cruza el foso (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin tocar los pinchos")


func test_claro_spike_bridge_is_crossable() -> void:
	await _setup("z3_claro", Vector2(19.0, 18.9))
	await _run_and_hop("move_right", 220)
	var p := _tile()
	print("  claro ramas: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 32.0, "cruza los pinchos (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin tocar los pinchos")


func test_claro_shard_reachable_with_pogo() -> void:
	await _setup("z3_claro", Vector2(24.6, 17.9))
	# Caer al hueco entre ramas y golpear hacia abajo sobre los pinchos.
	Input.action_press("move_right")
	var guard := 0
	while player.global_position.x < 25.55 * TILE and guard < 60:
		await t.get_tree().physics_frame
		guard += 1
	Input.action_release("move_right")
	Input.action_press("look_down")
	var best_y := 99.0
	for i in 70:
		await t.get_tree().physics_frame
		if player.velocity.y > 0.0 and player.global_position.y > 17.3 * TILE and player.global_position.x > 25.2 * TILE:
			Input.action_press("attack")
		else:
			Input.action_release("attack")
		best_y = minf(best_y, player.global_position.y / TILE)
	Input.action_release("attack")
	Input.action_release("look_down")
	await _frames(60)
	var p := _tile()
	print("  claro pogo: ", p, " altura mínima ", best_y, " máscaras ", GameState.data.masks)
	t.ok(best_y < 14.0, "el pogo eleva por encima de la rama del fragmento (%.1f)" % best_y)
	t.ok(p.y <= 14.05 and p.x > 24.9 and p.x < 27.1, "aterriza en la rama del fragmento (%.1f, %.1f)" % [p.x, p.y])


func test_claro_shard_not_reachable_by_jump() -> void:
	await _setup("z3_claro", Vector2(23.5, 17.9))
	var best_y := 99.0
	Input.action_press("jump")
	for i in 80:
		await t.get_tree().physics_frame
		best_y = minf(best_y, player.global_position.y / TILE)
	Input.action_release("jump")
	print("  claro salto normal altura mínima: ", best_y)
	t.ok(best_y > 14.6, "un salto normal no alcanza la rama (%.2f)" % best_y)


func test_cueva_block_is_climbable() -> void:
	await _setup("z3_cueva", Vector2(26.0, 16.9))
	await _run_and_hop("move_right", 220)
	var p := _tile()
	print("  cueva bloque: ", p)
	t.ok(p.x > 37.0, "supera el bloque (%.1f)" % p.x)


func test_copa_hover_platforms_to_l2() -> void:
	await _setup("z3_copa", Vector2(30.0, 37.9))
	await _frames(20)
	await _jump_up()                       # L1 → hp1 (x28-31, y36)
	await _walk_to(28.4)
	await _jump_dir("move_left", 60)       # hp1 → hp2 (x23-26, y34)
	await _walk_to(23.6)
	await _jump_up()                       # hp2 → hp3 (x21-24, y32)
	await _walk_to(21.4)
	await _jump_dir("move_left", 60)       # hp3 → L2 (x8-19, y30)
	var p := _tile()
	print("  copa hover→L2: ", p)
	t.ok(p.y < 30.2 and p.x < 19.0, "llega a L2 por las plataformas hover (%.1f, %.1f)" % [p.x, p.y])


func _jump_dir(dir: String, hold_dir_frames: int) -> void:
	Input.action_press(dir)
	Input.action_press("jump")
	await _frames(hold_dir_frames)
	Input.action_release(dir)
	await _frames(40 - mini(hold_dir_frames, 39))
	Input.action_release("jump")
	await _frames(40)

func test_raiz_shortcut_ledge() -> void:
	await _setup("z3_raiz", Vector2(39.0, 16.9))
	await _grapple_hop("move_right")
	await _grapple_hop("move_right")
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	await _frames(30)
	var p := _tile()
	print("  raiz atajo: ", p)
	t.ok(p.y < 6.2 and p.x > 43.5, "alcanza la cornisa del atajo (%.1f, %.1f)" % [p.x, p.y])
