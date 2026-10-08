extends RefCounted
## Armas: contenido completo, un arma por zona colocada en una sala, inventario
## (conseguir, equipar, cambiar, guardar) y efectos en combate.

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
	player.invuln = 9999.0


func after_each() -> void:
	for a in ["attack", "arma", "look_up", "look_down", "move_left", "move_right"]:
		Input.action_release(a)
	for n in t.get_tree().get_nodes_in_group("enemy"):
		n.queue_free()
	for c in t.get_children():
		if c is WeaponShots.Shot:
			c.queue_free()
	player.queue_free()
	room.queue_free()


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _dummy(offset_x: float) -> EnemyBase:
	var e: EnemyBase = load("res://scripts/enemies/etiqueta_sin_cerrar.gd").new()
	e.position = Vector2(20 * 64 + offset_x, FLOOR_Y - 2)
	t.add_child(e)
	return e


func _attack(target: EnemyBase = null, offset_x := 90.0) -> void:
	if target:
		target.global_position = Vector2(player.global_position.x + offset_x * player.facing, FLOOR_Y - 2)
		target.velocity = Vector2.ZERO
		target.knock_time = 0.0
		await _frames(1)
	player._attack_cd = 0.0
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	await _frames(20)


func test_contenido_de_las_armas() -> void:
	var list := ContentDB.armas_ordenadas()
	t.eq(list.size(), 10, "10 armas (Cursor + una por zona)")
	t.eq(str(list[0].id), "cursor", "el Cursor va primero")
	var zones := {}
	for w: Dictionary in list:
		for k in ["nombre", "estilo", "dano", "alcance", "cadencia", "especial", "descripcion", "leccion", "color"]:
			t.ok(w.has(k), "%s tiene %s" % [w.id, k])
		zones[int(w.zona)] = true
	for z in range(0, 10):
		t.ok(zones.has(z), "hay arma de la zona %d" % z)


func test_cada_zona_tiene_su_arma_en_una_sala() -> void:
	var found := {}
	for id: String in WorldMap.ROOMS.keys():
		for d: Dictionary in WorldMap.info(id).get("defs", []):
			if d.get("type") == "pickup" and d.get("kind") == "weapon":
				var w := ContentDB.arma(str(d.get("value", "")))
				t.ok(not w.is_empty(), "%s: el arma %s existe" % [id, d.get("value")])
				t.eq(int(w.get("zona", -1)), int(WorldMap.ROOMS[id].zone), "%s: el arma es de su zona" % id)
				found[int(WorldMap.ROOMS[id].zone)] = true
	for z in range(1, 10):
		t.ok(found.has(z), "la zona %d tiene un arma que recoger" % z)


func test_inventario_equipar_cambiar_y_guardar() -> void:
	t.eq(GameState.data.arma, "cursor", "se empieza con el Cursor")
	t.ok(not GameState.equip_weapon("mazo_mvc"), "no se equipa un arma que no tienes")
	GameState.grant_weapon("mazo_mvc")
	t.eq(GameState.data.arma, "mazo_mvc", "al conseguirla se equipa")
	GameState.grant_weapon("lanza_rest")
	GameState.equip_weapon("cursor")
	t.eq(GameState.cycle_weapon(), "lanza_rest", "cambiar: orden de zona (Lanza, zona 1)")
	t.eq(GameState.cycle_weapon(), "mazo_mvc", "cambiar: Mazo (zona 2)")
	t.eq(GameState.cycle_weapon(), "cursor", "cambiar: vuelve al Cursor")
	GameState.equip_weapon("mazo_mvc")
	var saved := GameState.to_dict()
	GameState.new_game()
	GameState.from_dict(saved)
	t.eq(GameState.data.arma, "mazo_mvc", "el arma equipada se guarda")
	t.ok(GameState.has_weapon("lanza_rest"), "el inventario se guarda")
	GameState.from_dict({"version": 2})
	t.eq(GameState.data.arma, "cursor", "partidas antiguas empiezan con el Cursor")


func test_el_dano_y_la_cadencia_dependen_del_arma() -> void:
	await _frames(10)
	var e := _dummy(90.0)
	await _frames(4)
	var hp0 := e.hp
	await _attack()
	t.eq(e.hp, hp0 - 1, "Cursor: 1 de daño")
	var cd_cursor := player.tuning.attack_cooldown
	GameState.grant_weapon("ancla_k8s")
	e.hp = 10
	e.max_hp = 10
	await _frames(30)
	await _attack(e)
	t.eq(e.hp, 7, "Ancla del Clúster: 3 de daño")
	player._start_attack()
	t.ok(player._attack_cd > cd_cursor * 1.9, "el Ancla es más lenta (%.2f s)" % player._attack_cd)


func test_arco_dispara_y_guadana_golpea_detras() -> void:
	await _frames(10)
	GameState.grant_weapon("arco_promesa")
	player.facing = 1.0
	await _attack()
	var bolts := 0
	for c in t.get_children():
		if c is WeaponShots.Shot:
			bolts += 1
	t.ok(bolts >= 1, "el Arco de Promesas dispara una flecha")
	var far := _dummy(520.0)
	far.hp = 5
	await _frames(40)
	t.ok(far.hp < 5, "la flecha alcanza a un enemigo lejano")
	far.queue_free()
	GameState.grant_weapon("guadana_paginada")
	var back := _dummy(-90.0)
	back.hp = 5
	await _frames(40)
	player.facing = 1.0
	await _attack()
	t.ok(back.hp <= 3, "la Guadaña golpea detrás (%d)" % back.hp)


func test_hoja_jwt_firma_el_tercer_golpe() -> void:
	await _frames(10)
	GameState.grant_weapon("hoja_jwt")
	var e := _dummy(90.0)
	e.max_hp = 20
	e.hp = 20
	e.knock_resist = 1.0
	await _frames(4)
	for i in 3:
		await _attack(e)
		await _frames(6)
	t.eq(e.hp, 20 - 1 - 1 - 3, "1 + 1 + 3 (firmado)")
