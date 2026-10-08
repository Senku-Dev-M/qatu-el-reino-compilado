extends RefCounted
## Habilidades de las zonas 1, 2, 8 y 9 y los puzles que las usan: cada
## santuario entrega su habilidad, y cada compuerta se abre SOLO con ella.

var t
var room: RoomBase
var player: Player

const TILE := 64.0
const ACTIONS := ["move_left", "move_right", "jump", "dash", "binding", "contenedor", "inspector"]


func _setup(room_id: String) -> void:
	GameState.new_game()
	room = load("res://rooms/%s.gd" % room_id).new()
	room.room_id = room_id
	t.add_child(room)
	room.build()
	player = Player.new()
	t.add_child(player)
	await t.get_tree().process_frame
	for e in t.get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	await _frames(4)


func after_each() -> void:
	for a in ACTIONS:
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


## Coloca al jugador de pie en la celda (x, y) (y = fila de sus pies).
func _place(x: float, y: int) -> void:
	player.place_at(Vector2((x + 0.5) * TILE, (y + 1) * TILE - 2.0))
	await _frames(12)


func _legend_has(room_id: String, type: String, key: String, value: String) -> bool:
	var inst: RoomBase = load("res://rooms/%s.gd" % room_id).new()
	var found := false
	for d: Dictionary in inst.legend().values():
		if str(d.get("type", "")) == type and (key == "" or str(d.get(key, "")) == value):
			found = true
	inst.free()
	return found


func test_cada_santuario_entrega_su_habilidad() -> void:
	var santuarios := {
		"z1_catacumbas": "rest_dash", "z2_santuario_binding": "data_binding",
		"z8_santuario_pod": "contenedor", "z9_santuario_inspector": "inspector",
	}
	for room_id: String in santuarios:
		var ability: String = santuarios[room_id]
		t.ok(_legend_has(room_id, "pickup", "value", ability), "%s entrega %s" % [room_id, ability])
		t.ok(ContentDB.habilidad(ability).size() > 0, "%s tiene ficha en habilidades.json" % ability)


func test_no_quedan_anclas_de_gancho_en_las_zonas_nuevas() -> void:
	# El gancho es la habilidad de la zona 3: en las zonas 1, 2, 8 y 9 no se
	# puede usar todavía, así que no debe haber anclas.
	for room_id: String in WorldMap.ROOMS.keys():
		if not (room_id.begins_with("z1_") or room_id.begins_with("z2_") or room_id.begins_with("z8_") or room_id.begins_with("z9_")):
			continue
		t.ok(not _legend_has(room_id, "anchor", "", ""), "%s no tiene anclas" % room_id)


func test_rest_dash_atraviesa_el_terminal_y_abre_la_compuerta() -> void:
	await _setup("z1_catacumbas")
	var gate: Node = room.get_entity("gate1")
	var term: Node = room.get_entity("term1")
	t.ok(gate != null and term != null, "hay terminal y compuerta")
	# Sin la habilidad no pasa nada.
	await _place(21, 12)
	Input.action_press("move_right")
	await _frames(3)
	await _tap("dash")
	await _frames(30)
	Input.action_release("move_right")
	t.ok(not gate.is_open(), "sin REST Dash la compuerta sigue cerrada")
	GameState.grant_ability("rest_dash")
	await _place(21, 12)
	Input.action_press("move_right")
	await _frames(3)
	await _tap("dash")
	await _frames(30)
	Input.action_release("move_right")
	t.ok(term.sent, "el terminal recibe la petición")
	await _frames(150)
	t.ok(gate.is_open(), "la compuerta de capas se abre (200 OK)")


func test_data_binding_enlaza_la_compuerta_y_la_plataforma() -> void:
	await _setup("z2_aguja_clean")
	var gate: Node = room.get_entity("gate1")
	var node: Node2D = room.get_entity("node1")
	var cell := node.global_position / TILE
	await _place(cell.x - 1.5, int(cell.y) - 1)
	await _tap("binding")
	await _frames(10)
	t.ok(not node.bound, "sin Data Binding no se enlaza")
	GameState.grant_ability("data_binding")
	await _tap("binding")
	await _frames(150)
	t.ok(node.bound and gate.is_open(), "enlazado: la compuerta se abre")
	await _tap("binding")
	await _frames(150)
	t.ok(not node.bound and not gate.is_open(), "desenlazado: la compuerta vuelve a cerrarse")
	await after_each()
	await t.get_tree().process_frame
	await _setup("z2_santuario_binding")
	GameState.grant_ability("data_binding")
	var plat: Node2D = room.get_entity("plat1")
	var n2: Node2D = room.get_entity("node1")
	var y0 := plat.global_position.y
	var c2 := n2.global_position / TILE
	await _place(c2.x - 1.5, int(c2.y) - 1)
	await _tap("binding")
	await _frames(150)
	t.ok(absf(plat.global_position.y - (y0 - 4 * TILE)) < 4.0, "la plataforma enlazada sube 4 tiles (%.0f px)" % (y0 - plat.global_position.y))


func test_contenedor_despliega_un_pod_sobre_el_nodo() -> void:
	await _setup("z8_hangar_k8s")
	var gate: Node = room.get_entity("gate1")
	var nodo: Node2D = room.get_entity("nodo1")
	var cell := nodo.global_position / TILE
	GameState.grant_ability("contenedor")
	await _place(cell.x - 0.5, int(cell.y) - 1)
	await _tap("contenedor")
	await _frames(4)
	t.ok(player.active_pod() == null, "en el suelo no se despliega (hay que saltar)")
	Input.action_press("jump")
	await _frames(14)
	await _tap("contenedor")
	Input.action_release("jump")
	await _frames(4)
	t.ok(player.active_pod() != null, "en el aire aparece el Pod")
	await _frames(150)
	t.ok(nodo.deployed and gate.is_open(), "el Deployment queda listo y abre la compuerta")


func test_inspector_revela_la_asercion_y_abre_la_barrera() -> void:
	await _setup("z9_torre_monitoreo")
	var barrier: Node = room.get_entity("barrier1")
	var node: Node2D = room.get_entity("assert1")
	var cell := node.global_position / TILE
	await _place(cell.x - 2.5, int(cell.y) - 1)
	await _tap("inspector")
	await _frames(20)
	t.ok(not node.verified, "sin Inspector la aserción sigue oculta")
	GameState.grant_ability("inspector")
	await _tap("inspector")
	await _frames(150)
	t.ok(node.verified and barrier.is_open(), "revelada: la barrera WAF se abre")


func test_las_compuertas_de_habilidad_estan_en_la_salida() -> void:
	# Compuertas de 3 tiles de alto pegadas a la puerta: no se pueden saltar.
	var salas := {"z1_catacumbas": "gate1", "z1_cripta": "gate1", "z2_aguja_clean": "gate1",
		"z8_hangar_k8s": "gate1", "z9_torre_monitoreo": "barrier1"}
	for room_id: String in salas:
		await _setup(room_id)
		var g: Node2D = room.get_entity(salas[room_id])
		t.ok(g != null, "%s tiene su compuerta" % room_id)
		if g:
			t.eq(int(g.h), 3, "%s: compuerta de 3 tiles" % room_id)
			var cols := int(room.layout()[0].length())
			t.ok(int(g.global_position.x / TILE) >= cols - 3, "%s: la compuerta cierra la salida" % room_id)
		await after_each()
		await t.get_tree().process_frame


func test_el_manual_tiene_dialogos_en_forma_de_lista() -> void:
	# npc.gd hace g.intro.duplicate() y append_array: un texto suelto rompería.
	for room_id: String in WorldMap.ROOMS.keys():
		var g := ContentDB.guia(room_id)
		if g.is_empty():
			continue
		t.ok(g.get("intro", []) is Array, "%s: intro es una lista" % room_id)
		t.ok(g.get("cierre", []) is Array, "%s: cierre es una lista" % room_id)


func test_objetos_apoyados_y_sin_terreno_encima() -> void:
	# Tablillas, cofres, NPC... apoyados en suelo y sin plataformas que los
	# atraviesen (las plataformas de acceso se generan respetando ese hueco).
	var alto := {"tablilla": 2, "sello": 3, "npc": 2, "bench": 1, "chest": 1, "pickup": 1, "sign": 2,
		"rest_terminal": 1, "binding_node": 1, "pod_launcher": 2}
	for room_id: String in WorldMap.ROOMS.keys():
		if not (room_id.begins_with("z1_") or room_id.begins_with("z2_") or room_id.begins_with("z8_") or room_id.begins_with("z9_")):
			continue
		var inst: RoomBase = load("res://rooms/%s.gd" % room_id).new()
		var rows := inst.layout()
		var legend := inst.legend()
		var fallos := []
		for y in rows.size():
			for x in rows[y].length():
				var ch := rows[y][x]
				if not legend.has(ch):
					continue
				var type := str(legend[ch].get("type", ""))
				if not alto.has(type):
					continue
				var below := rows[y + 1][x] if y + 1 < rows.size() else "#"
				if below != "#" and below != "=":
					fallos.append("%s(%d,%d) flota" % [type, x, y])
				for yy in range(y - int(alto[type]), y + 1):
					for xx in [x - 1, x, x + 1]:
						if yy < 0 or xx < 0 or xx >= rows[yy].length() or (xx == x and yy == y):
							continue
						if rows[yy][xx] == "#" or rows[yy][xx] == "=":
							fallos.append("%s(%d,%d) atravesado en (%d,%d)" % [type, x, y, xx, yy])
		inst.free()
		t.ok(fallos.is_empty(), "%s: colocación limpia %s" % [room_id, ", ".join(fallos)])
