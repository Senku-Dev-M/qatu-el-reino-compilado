extends RefCounted
## Bots de la zona 7: habilidad Tokens, arcos lectores (401/403/200),
## puentes de luz que dependen del token y renovación con el refresh.

var t
var room: RoomBase
var player: Player

const TILE := 64.0


func _setup(room_id: String, start_tile: Vector2) -> void:
	GameState.new_game()
	GameState.grant_ability("token")
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


# --- Habilidad Tokens ----------------------------------------------------------------

func test_token_grant_expiry_and_refresh() -> void:
	await _setup("z7_barbacana", Vector2(24.0, 18.9))
	t.ok(not player.token_valid(), "empieza sin token")
	t.ok(not player.refresh_access_token(), "sin refresh no se puede renovar")
	room.get_entity("autorizador_visitante").interact(player)
	t.ok(player.token_valid(), "el autorizador emite el access token")
	t.ok(player.token_valid("visitante"), "con el alcance pedido")
	t.ok(not player.token_valid("admin"), "no vale para otro alcance")
	t.ok(player.has_refresh, "también entrega el refresh token")
	await _seconds(player.TOKEN_TTL + 0.3)
	t.ok(not player.token_valid(), "el access token caduca")
	t.ok(player.has_refresh, "el refresh sigue vigente")
	t.ok(player.refresh_access_token(), "se renueva con el refresh")
	t.ok(player.token_valid("visitante"), "conserva el alcance")
	t.ok(not player.refresh_access_token(), "hay un enfriamiento entre renovaciones")
	player.revoke_token()
	t.ok(not player.token_valid(), "un robo revoca el access token")
	await _seconds(player.REFRESH_COOLDOWN + 0.2)
	t.ok(player.refresh_access_token(), "tras el robo se puede renovar")


func test_sso_charm_extends_ttl() -> void:
	await _setup("z7_barbacana", Vector2(24.0, 18.9))
	var base := player.token_ttl_max()
	GameState.grant_charm("sso")
	t.ok(GameState.equip_charm("sso", 1), "equipa SSO")
	t.ok(player.token_ttl_max() > base * 1.4, "SSO alarga la vida del token")


func test_mfa_charm_absorbs_first_hit() -> void:
	await _setup("z7_barbacana", Vector2(24.0, 18.9))
	GameState.grant_charm("mfa")
	t.ok(GameState.equip_charm("mfa", 2), "equipa MFA")
	player.take_damage(1, player.global_position + Vector2(80, 0))
	t.eq(GameState.data.masks, 5, "el primer golpe de la sala no quita máscara")
	player.invuln = 0.0
	player.take_damage(1, player.global_position + Vector2(80, 0))
	t.eq(GameState.data.masks, 4, "el segundo sí")


# --- Arcos lectores -------------------------------------------------------------------

func test_lector_status_401_403_200() -> void:
	await _setup("z7_patio", Vector2(24.0, 20.9))
	var lector = room.get_entity("lector_vendedor")
	t.eq(lector.status_for(player), "401", "sin token: 401")
	room.get_entity("autorizador_visitante").interact(player)
	t.eq(lector.status_for(player), "403", "con el alcance equivocado: 403")
	room.get_entity("autorizador_vendedor").interact(player)
	t.eq(lector.status_for(player), "200", "con el alcance correcto: 200")


func test_barbacana_lector_and_bridge() -> void:
	await _setup("z7_barbacana", Vector2(30.0, 18.9))
	await _run_to(38.0, 200)
	t.ok(_tile().x < 36.0, "el arco lector bloquea sin token (%.1f)" % _tile().x)
	await _run_to(24.5)
	room.get_entity("autorizador_visitante").interact(player)
	t.ok(player.token_valid("visitante"), "token obtenido")
	await _frames(20)
	await _run_to(46.0, 420)
	var p := _tile()
	print("  barbacana: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 45.0 and p.y < 19.2, "cruza el arco y el puente de tokens (%.1f)" % p.x)
	t.eq(GameState.data.masks, 5, "sin caer al foso")


func test_bridge_disappears_when_token_expires() -> void:
	await _setup("z7_barbacana", Vector2(24.0, 18.9))
	room.get_entity("autorizador_visitante").interact(player)
	var puente = room.get_entity("puente_barbacana")
	await _frames(4)
	t.ok(not puente.bodies[0].get_child(0).disabled, "con token, el puente existe")
	player.token_ttl = 0.0
	await _frames(6)
	t.ok(puente.bodies[0].get_child(0).disabled, "al caducar, el puente desaparece")


func test_patio_bridge_needs_vendedor_scope() -> void:
	await _setup("z7_patio", Vector2(38.0, 20.9))
	room.get_entity("autorizador_visitante").interact(player)
	await _frames(4)
	var puente = room.get_entity("puente_patio")
	t.ok(puente.bodies[0].get_child(0).disabled, "el puente pide scope vendedor")
	room.get_entity("autorizador_vendedor").interact(player)
	await _frames(6)
	t.ok(not puente.bodies[0].get_child(0).disabled, "con el token de vendedor aparece")
	await _jump_toward(41.6)      # fila 19
	await _jump_toward(38.6)      # fila 17
	await _jump_toward(41.6)      # fila 15
	await _jump_toward(44.6)      # terraza (fila 13)
	var p := _tile()
	print("  patio: ", p)
	t.ok(p.y < 13.2 and p.x > 43.5, "sube a la terraza (%.1f, %.1f)" % [p.x, p.y])


func test_torre_sso_one_token_two_arcos() -> void:
	await _setup("z7_torre", Vector2(13.0, 24.9))
	room.get_entity("idp").interact(player)
	t.ok(player.token_valid("admin"), "token de admin del IdP")
	await _frames(6)
	await _run_to(15.3)
	await _jump_toward(17.4)      # fila 23
	await _jump_toward(19.6)      # fila 21
	await _jump_toward(17.4)      # fila 19
	await _jump_toward(19.6)      # fila 17
	await _jump_toward(17.4)      # fila 15
	await _jump_toward(19.6)      # fila 13
	await _jump_toward(23.0)      # galería
	var p := _tile()
	t.ok(p.y < 13.2 and p.x > 22.0, "sube por la escalera de tokens (%.1f, %.1f)" % [p.x, p.y])
	var a1 = room.get_entity("lector_torre_1")
	var a2 = room.get_entity("lector_torre_2")
	t.eq(a1.status_for(player), "200", "el primer arco se abre")
	t.eq(a2.status_for(player), "200", "y el segundo con el mismo token: SSO")


func test_sesiones_gate_needs_refresh() -> void:
	await _setup("z7_sesiones", Vector2(38.0, 18.9))
	# Llega con el refresh de la torre y el access token ya caducado.
	player.grant_token("admin")
	player.token_ttl = 0.0
	var lector = room.get_entity("lector_sesiones")
	t.eq(lector.status_for(player), "401", "sin access token vigente: 401")
	await _run_to(42.0, 120)
	t.ok(_tile().x < 41.0, "el arco bloquea (%.1f)" % _tile().x)
	t.ok(player.refresh_access_token(), "renueva con el refresh")
	await _frames(20)
	t.eq(lector.status_for(player), "200", "ahora pasa")
	await _run_to(44.0, 120)
	t.ok(_tile().x > 43.0, "cruza el arco final (%.1f)" % _tile().x)
