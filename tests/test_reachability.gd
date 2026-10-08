extends RefCounted
## Comprueba que en TODAS las salas se puede llegar a lo obligatorio (puertas,
## tablillas, sellos, bancos, NPC, objetos y portales) solo caminando y
## saltando: salto de 2 filas como maximo y huecos de 4 tiles.
##
## Esta prueba existe porque es facil disenar una sala imposible sin darse
## cuenta: el suelo esta en la fila del `frame`, no en la fila donde se ponen
## las entidades, asi que una plataforma "a dos filas" suele quedar a tres.

var t

## Excepciones documentadas: se alcanzan con una habilidad de la zona, no a pie.
const ABILITY_GATED := {
	# Zona 3: el pogo y el gancho son la mecanica de la sala.
	"z3_claro": ["pickup fragmento (25,13)"],              # pogo (test_level_routes: claro pogo)
	# Escalones de etiquetas: bloques macizos de 2 filas que se suben pegado al
	# borde (el modelo conservador exige 2 tiles de carrerilla; en juego se suben).
	"z3_galeria": ["tablilla L08 (37,14)", "tablilla L09 (44,12)"],
	"z3_copa": ["tablilla L22 (21,14)", "tablilla L20 (35,37)"],  # nodos hover y gancho
	# Zona 4: el contenedor flex es el ascensor de la sala.
	"z4_caravana": ["pickup fragmento (2,10)", "tablilla L37 (30,13)"],
	# Zona 4: escalera que forma el contenedor flex en column.
	"z4_terrazas": ["pickup amuleto (49,3)"],
	# Zona 5: cornisa que aparece al encadenar promesas.
	"z5_manantial": ["pickup amuleto (54,14)"],
	# Zona 6: balda que sale al pasar de pagina en el paginador.
	"z6_estanteria": ["tablilla L79 (34,14)"],
}


func _rooms() -> Array:
	var ids := WorldMap.ROOMS.keys()
	ids.sort()
	return ids


func test_todo_lo_obligatorio_es_alcanzable() -> void:
	var total := 0
	for id in _rooms():
		var path := "res://rooms/%s.gd" % id
		if not ResourceLoader.exists(path):
			continue
		var room = load(path).new()
		room.room_id = id
		var map := ReachMap.new().load_room(room)
		var allowed: Array = ABILITY_GATED.get(id, [])
		for label in map.unreachable_required():
			if label in allowed:
				continue
			total += 1
			t.ok(false, "%s: no se puede llegar a %s" % [id, label])
	t.eq(total, 0, "ninguna entidad obligatoria queda fuera de alcance")


func test_ninguna_puerta_es_un_callejon_sin_salida() -> void:
	# Entrar por una puerta y no poder salir por ninguna deja la partida rota.
	# Los atajos de un solo sentido si valen: basta con alcanzar OTRA puerta.
	var atrapado := 0
	for id in _rooms():
		var path := "res://rooms/%s.gd" % id
		if not ResourceLoader.exists(path):
			continue
		var room = load(path).new()
		room.room_id = id
		var map := ReachMap.new().load_room(room)
		var entries: Array = map.door_entries()
		if entries.size() < 2:
			continue
		for entry in entries:
			var seen: Dictionary = map.reachable(entry.spots)
			var salidas := 0
			for e in map.entities():
				if e.type != "door":
					continue
				for dy in [1, 2, 0]:
					if seen.has((int(e.y) + dy) * 1000 + int(e.x)):
						salidas += 1
						break
			if salidas < 1:
				atrapado += 1
				t.ok(false, "%s: entrando por %s no se alcanza ninguna puerta" % [id, entry.id])
	t.eq(atrapado, 0, "ninguna puerta deja al jugador encerrado")


func test_el_modelo_coincide_con_la_fisica() -> void:
	# Los limites del mapa tienen que seguir a player_tuning: si alguien cambia
	# el salto, esta prueba avisa de que hay que revisar las salas.
	var tuning := PlayerTuning.new()
	var jump_px: float = (tuning.jump_velocity * tuning.jump_velocity) / (2.0 * tuning.gravity)
	t.ok(jump_px < (ReachMap.MAX_UP + 1) * 64.0,
		"el salto (%.0f px) no llega a %d filas" % [jump_px, ReachMap.MAX_UP + 1])
	t.ok(jump_px >= ReachMap.MAX_UP * 64.0,
		"el salto (%.0f px) si llega a %d filas" % [jump_px, ReachMap.MAX_UP])
