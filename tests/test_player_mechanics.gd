extends RefCounted
## Pruebas de integración del jugador con entradas simuladas.

var t
var room: RoomBase
var player: Player

const FLOOR_Y := 17 * 64.0


func before_each() -> void:
	GameState.new_game()
	room = load("res://tests/fixtures/test_room.gd").new()
	t.add_child(room)
	room.build()
	player = Player.new()
	t.add_child(player)
	player.global_position = Vector2(20 * 64, FLOOR_Y - 2)


func after_each() -> void:
	for a in ["move_left", "move_right", "jump", "attack", "grapple", "heal", "look_up", "look_down"]:
		Input.action_release(a)
	player.queue_free()
	room.queue_free()


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func test_player_lands_and_runs() -> void:
	await _frames(20)
	t.ok(player.is_on_floor(), "está en el suelo")
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	t.ok(player.global_position.x - x0 > 150.0, "corre a la derecha (%.0f px)" % (player.global_position.x - x0))
	t.eq(player.facing, 1.0, "mira a la derecha")


func test_jump_height_is_about_three_tiles() -> void:
	await _frames(20)
	var y0 := player.global_position.y
	var min_y := y0
	Input.action_press("jump")
	for i in 90:
		await t.get_tree().physics_frame
		min_y = minf(min_y, player.global_position.y)
	Input.action_release("jump")
	var height := y0 - min_y
	print("  salto: %.0f px" % height)
	t.ok(height > 150.0 and height < 192.0, "altura de salto entre 150 y 192 px (%.0f)" % height)


func test_short_hop_is_lower() -> void:
	await _frames(20)
	var y0 := player.global_position.y
	var min_y := y0
	Input.action_press("jump")
	await _frames(4)
	Input.action_release("jump")
	for i in 60:
		await t.get_tree().physics_frame
		min_y = minf(min_y, player.global_position.y)
	t.ok(y0 - min_y < 120.0, "salto corto más bajo (%.0f px)" % (y0 - min_y))


func test_attack_kills_crawler_and_fills_energy() -> void:
	await _frames(20)
	var e: EnemyBase = load("res://scripts/enemies/etiqueta_sin_cerrar.gd").new()
	e.position = player.global_position + Vector2(90, 0)
	room.entity_layer.add_child(e)
	await _frames(10)
	for i in 4:
		if e.dead:
			break
		player.facing = 1.0
		e.global_position.x = player.global_position.x + 90
		await _tap("attack")
		await _frames(50)
	print("  kills: ", GameState.kills("etiqueta_sin_cerrar"), " energia: ", GameState.data.energy)
	t.ok(GameState.kills("etiqueta_sin_cerrar") >= 1, "bestiario registra la derrota")
	t.ok(GameState.data.energy > 0.2, "golpear llena energía (%.2f)" % GameState.data.energy)


func test_grapple_pulls_toward_anchor() -> void:
	GameState.grant_ability("event_listener")
	await _frames(20)
	var a: Node2D = load("res://scripts/objects/anchor.gd").new()
	room.entity_layer.add_child(a)
	a.global_position = player.global_position + Vector2(160, -230)
	a.setup(room, {"type": "anchor"})
	await _frames(4)
	var d0 := player.global_position.distance_to(a.global_position)
	await _tap("grapple")
	await _frames(20)
	var d1 := player.global_position.distance_to(a.global_position)
	print("  gancho: %.0f -> %.0f" % [d0, d1])
	t.ok(d1 < d0 - 120.0, "el gancho acerca al jugador (%.0f → %.0f)" % [d0, d1])


func test_grapple_requires_ability() -> void:
	await _frames(20)
	var a: Node2D = load("res://scripts/objects/anchor.gd").new()
	room.entity_layer.add_child(a)
	a.global_position = player.global_position + Vector2(100, -200)
	a.setup(room, {"type": "anchor"})
	await _frames(4)
	await _tap("grapple")
	await _frames(5)
	t.ok(player.state != Player.State.GRAPPLE, "sin habilidad no hay gancho")


func test_heal_restores_mask() -> void:
	await _frames(20)
	GameState.damage(2)
	GameState.add_energy(0.5)
	Input.action_press("heal")
	await _frames(130)
	Input.action_release("heal")
	t.eq(GameState.data.masks, 4, "Hotfix recupera una máscara")


func test_spikes_damage_and_respawn() -> void:
	await _frames(20)
	var safe := player.global_position
	var hz := Hazard.new()
	hz.add_rect(Rect2(0, 0, 64, 40))
	room.add_child(hz)
	hz.global_position = player.global_position + Vector2(-32, -30)
	await _frames(40)
	t.eq(GameState.data.masks, 4, "los pinchos quitan una máscara")
	hz.queue_free()
