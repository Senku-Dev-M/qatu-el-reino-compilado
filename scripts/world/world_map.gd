class_name WorldMap
extends RefCounted
## Posición de cada sala en el mapa (en tiles globales) y conexiones
## derivadas de las puertas de cada sala.

const ROOMS := {
	"hub_plaza": {"pos": Vector2i(0, 0), "zone": 0},
	"hub_sanctum": {"pos": Vector2i(70, 0), "zone": 10},
	
	# Zona 1: Ruinas del Backend
	"z1_atrio": {"pos": Vector2i(0, 0), "zone": 1},
	"z1_catacumbas": {"pos": Vector2i(61, -2), "zone": 1},
	"z1_galeria": {"pos": Vector2i(126, -2), "zone": 1},
	"z1_altar": {"pos": Vector2i(193, 0), "zone": 1},
	"z1_boveda": {"pos": Vector2i(258, -2), "zone": 1},
	"z1_cripta": {"pos": Vector2i(325, 0), "zone": 1},
	"z1_bastion": {"pos": Vector2i(390, -2), "zone": 1},
	"z1_arena": {"pos": Vector2i(457, 0), "zone": 1},

	# Zona 2: Torres de Arquitectura
	"z2_torre_base": {"pos": Vector2i(0, 0), "zone": 2},
	"z2_sala_flujo": {"pos": Vector2i(61, -2), "zone": 2},
	"z2_galeria_spa": {"pos": Vector2i(126, -2), "zone": 2},
	"z2_santuario_binding": {"pos": Vector2i(193, 0), "zone": 2},
	"z2_terraza_mv": {"pos": Vector2i(258, -2), "zone": 2},
	"z2_aguja_clean": {"pos": Vector2i(325, 0), "zone": 2},
	"z2_mirador_frameworks": {"pos": Vector2i(390, -2), "zone": 2},
	"z2_arena": {"pos": Vector2i(457, 0), "zone": 2},

	# Zona 3: Bosque del DOM
	"z3_raiz": {"pos": Vector2i(0, 0), "zone": 3},
	"z3_galeria": {"pos": Vector2i(58, 0), "zone": 3},
	"z3_claro": {"pos": Vector2i(124, -2), "zone": 3},
	"z3_tronco": {"pos": Vector2i(192, 0), "zone": 3},
	"z3_copa": {"pos": Vector2i(242, -36), "zone": 3},
	"z3_motor": {"pos": Vector2i(204, -31), "zone": 3},
	"z3_cueva": {"pos": Vector2i(284, -44), "zone": 3},
	"z3_arena": {"pos": Vector2i(342, -46), "zone": 3},

	# Zona 4: Cañones Flexibles
	"z4_mirador": {"pos": Vector2i(0, 0), "zone": 4},
	"z4_desfiladero": {"pos": Vector2i(52, -2), "zone": 4},
	"z4_caravana": {"pos": Vector2i(118, -6), "zone": 4},
	"z4_terrazas": {"pos": Vector2i(184, -11), "zone": 4},
	"z4_atalaya": {"pos": Vector2i(246, -19), "zone": 4},
	"z4_taller": {"pos": Vector2i(308, -15), "zone": 4},
	"z4_arena": {"pos": Vector2i(362, -17), "zone": 4},

	# Zona 5: Ríos Asíncronos
	"z5_embarcadero": {"pos": Vector2i(0, 0), "zone": 5},
	"z5_esclusas": {"pos": Vector2i(54, -2), "zone": 5},
	"z5_compuerta": {"pos": Vector2i(114, -2), "zone": 5},
	"z5_manantial": {"pos": Vector2i(172, -4), "zone": 5},
	"z5_delta": {"pos": Vector2i(238, -6), "zone": 5},
	"z5_aduana": {"pos": Vector2i(298, -12), "zone": 5},
	"z5_observatorio": {"pos": Vector2i(360, -12), "zone": 5},
	"z5_arena": {"pos": Vector2i(418, -12), "zone": 5},

	# Zona 6: Archivo Paginado
	"z6_vestibulo": {"pos": Vector2i(0, 0), "zone": 6},
	"z6_estanteria": {"pos": Vector2i(54, -6), "zone": 6},
	"z6_catalogo": {"pos": Vector2i(114, -18), "zone": 6},
	"z6_galeria": {"pos": Vector2i(172, -18), "zone": 6},
	"z6_sotano": {"pos": Vector2i(236, -18), "zone": 6},
	"z6_boveda": {"pos": Vector2i(296, -20), "zone": 6},
	"z6_pasillo": {"pos": Vector2i(358, -30), "zone": 6},
	"z6_arena": {"pos": Vector2i(420, -30), "zone": 6},

	# Zona 7: Ciudadela IAM
	"z7_puesto": {"pos": Vector2i(0, 0), "zone": 7},
	"z7_barbacana": {"pos": Vector2i(54, -2), "zone": 7},
	"z7_patio": {"pos": Vector2i(112, -4), "zone": 7},
	"z7_capilla": {"pos": Vector2i(174, -10), "zone": 7},
	"z7_muralla": {"pos": Vector2i(232, -10), "zone": 7},
	"z7_torre": {"pos": Vector2i(292, -16), "zone": 7},
	"z7_sesiones": {"pos": Vector2i(336, -22), "zone": 7},
	"z7_arena": {"pos": Vector2i(394, -22), "zone": 7},

	# Zona 8: Puerto de Contenedores
	"z8_muelle": {"pos": Vector2i(0, 0), "zone": 8},
	"z8_darsena_docker": {"pos": Vector2i(61, -2), "zone": 8},
	"z8_astillero_compose": {"pos": Vector2i(126, 0), "zone": 8},
	"z8_santuario_pod": {"pos": Vector2i(187, 0), "zone": 8},
	"z8_gruas_cicd": {"pos": Vector2i(159, -31), "zone": 8},
	"z8_hangar_k8s": {"pos": Vector2i(226, -29), "zone": 8},
	"z8_faro_swarm": {"pos": Vector2i(291, -31), "zone": 8},
	"z8_arena": {"pos": Vector2i(257, -54), "zone": 8},

	# Zona 9: Laboratorio de Pruebas
	"z9_vestibulo_qa": {"pos": Vector2i(0, 0), "zone": 9},
	"z9_sala_piramide": {"pos": Vector2i(61, 0), "zone": 9},
	"z9_camara_selenium": {"pos": Vector2i(122, -2), "zone": 9},
	"z9_santuario_inspector": {"pos": Vector2i(187, 0), "zone": 9},
	"z9_bunker_owasp": {"pos": Vector2i(91, -31), "zone": 9},
	"z9_torre_monitoreo": {"pos": Vector2i(158, -29), "zone": 9},
	"z9_galeria_metricas": {"pos": Vector2i(223, -31), "zone": 9},
	"z9_arena": {"pos": Vector2i(290, -29), "zone": 9},
}

static var _cache := {}


## Datos de la sala: {name, size (Vector2i), doors: [{id, to, to_door, cell}], defs}
static func info(room_id: String) -> Dictionary:
	if _cache.has(room_id):
		return _cache[room_id]
	var path := "res://rooms/%s.gd" % room_id
	if not ResourceLoader.exists(path):
		return {}
	var room: RoomBase = load(path).new()
	room.room_id = room_id
	var defs := room.entity_defs()
	var doors := []
	for d in defs:
		if d.get("type") in ["door", "portal"] and d.has("to"):
			doors.append(d)
	var data := {"name": room.display_name, "size": room.size_tiles(), "doors": doors, "defs": defs, "zone": room.zone}
	room.free()
	_cache[room_id] = data
	return data


static func rect(room_id: String) -> Rect2:
	var i := info(room_id)
	if i.is_empty() or not ROOMS.has(room_id):
		return Rect2()
	return Rect2(Vector2(ROOMS[room_id].pos), Vector2(i.size))


static func neighbors(room_id: String) -> Array:
	var out := []
	for d in info(room_id).get("doors", []):
		if d.get("type") == "door" and not (d.to in out):
			out.append(d.to)
	return out
