extends RefCounted

var t

const ROOM_IDS := [
	"hub_plaza", "hub_sanctum",
	# Zona 1: Ruinas del Backend
	"z1_atrio", "z1_catacumbas", "z1_galeria", "z1_altar", "z1_boveda", "z1_cripta", "z1_bastion", "z1_arena",
	# Zona 2: Torres de Arquitectura
	"z2_torre_base", "z2_sala_flujo", "z2_galeria_spa", "z2_santuario_binding", "z2_terraza_mv", "z2_aguja_clean", "z2_mirador_frameworks", "z2_arena",
	# Zona 3: Bosque del DOM
	"z3_raiz", "z3_galeria", "z3_claro", "z3_tronco", "z3_copa", "z3_motor", "z3_cueva", "z3_arena",
	# Zona 4: Cañones Flexibles
	"z4_mirador", "z4_desfiladero", "z4_caravana", "z4_terrazas", "z4_atalaya", "z4_taller", "z4_arena",
	# Zona 5: Ríos Asíncronos
	"z5_embarcadero", "z5_esclusas", "z5_compuerta", "z5_manantial", "z5_delta", "z5_aduana", "z5_observatorio", "z5_arena",
	# Zona 6: Archivo Paginado
	"z6_vestibulo", "z6_estanteria", "z6_catalogo", "z6_galeria", "z6_sotano", "z6_boveda", "z6_pasillo", "z6_arena",
	# Zona 7: Ciudadela IAM
	"z7_puesto", "z7_barbacana", "z7_patio", "z7_capilla", "z7_muralla", "z7_torre", "z7_sesiones", "z7_arena",
	# Zona 8: Puerto de Contenedores
	"z8_muelle", "z8_darsena_docker", "z8_astillero_compose", "z8_santuario_pod", "z8_gruas_cicd", "z8_hangar_k8s", "z8_faro_swarm", "z8_arena",
	# Zona 9: Laboratorio de Pruebas
	"z9_vestibulo_qa", "z9_sala_piramide", "z9_camara_selenium", "z9_santuario_inspector", "z9_bunker_owasp", "z9_torre_monitoreo", "z9_galeria_metricas", "z9_arena"
]


func _room(id: String) -> RoomBase:
	var room: RoomBase = load("res://rooms/%s.gd" % id).new()
	room.room_id = id
	return room


func test_all_rooms_listed_in_world_map() -> void:
	for id in ROOM_IDS:
		t.ok(WorldMap.ROOMS.has(id), "%s en WorldMap" % id)
		t.ok(ResourceLoader.exists("res://rooms/%s.gd" % id), "%s existe" % id)


func test_rows_are_rectangular_and_min_size() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		var rows := room.layout()
		t.ok(rows.size() >= 17, "%s: al menos 17 filas" % id)
		for r in rows:
			t.eq(r.length(), rows[0].length(), "%s: filas del mismo ancho" % id)
		t.ok(rows[0].length() >= 30, "%s: al menos 30 columnas" % id)
		room.free()


func test_no_unknown_entities() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		for d in room.entity_defs():
			t.ok(d.get("type") != "_unknown", "%s: carácter sin leyenda '%s' en %s" % [id, d.get("char", ""), d.cell])
			t.ok(RoomBase.ENTITY_SCRIPTS.has(d.get("type", "")) or d.get("type") == "_unknown", "%s: tipo válido %s" % [id, d.get("type")])
		room.free()


func test_doors_on_edges_and_reciprocal() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		var w := room.size_tiles().x
		for d in room.entity_defs():
			if d.type != "door":
				continue
			t.ok(d.cell.x == 0 or d.cell.x == w - 1 or d.cell.y == 4 or d.cell.y == 14, "%s: puerta %s en un borde" % [id, d.id])
			t.ok(ROOM_IDS.has(d.to), "%s: puerta %s apunta a sala existente %s" % [id, d.id, d.to])
			if ROOM_IDS.has(d.to):
				var other := _room(d.to)
				var back := other.entity_defs().filter(func(o): return o.id == d.to_door)
				t.ok(back.size() == 1, "%s: %s → %s:%s existe" % [id, d.id, d.to, d.to_door])
				if back.size() == 1 and back[0].type == "door":
					t.eq(back[0].to, id, "%s:%s es recíproca" % [id, d.id])
				other.free()
			# Hay suelo bajo la puerta.
			var rows := room.layout()
			t.eq(rows[d.cell.y + 1][d.cell.x], "#", "%s: suelo bajo la puerta %s" % [id, d.id])
		room.free()


func test_doors_have_clearance() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		var rows := room.layout()
		for d in room.entity_defs():
			if d.type != "door":
				continue
			var h := int(d.get("h", 3))
			for dy in range(1, h):
				var check_y: int = d.cell.y - dy
				if check_y >= 0 and check_y < rows.size():
					t.ok(rows[check_y][d.cell.x] != "#", "%s: puerta %s despejada en y=%d" % [id, d.id, check_y])
		room.free()


func test_portals_point_to_existing_spawns() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		for d in room.entity_defs():
			if d.type == "portal" and d.has("to"):
				var other := _room(d.to)
				t.ok(other.entity_defs().any(func(o): return o.id == d.to_door), "%s: portal %s → %s:%s" % [id, d.id, d.to, d.to_door])
				other.free()
		room.free()


func test_content_references_exist() -> void:
	var db = t.get_node("/root/ContentDB")
	var tablillas := {}
	var sellos := {}
	for id in ROOM_IDS:
		var room := _room(id)
		for d in room.entity_defs():
			match d.type:
				"tablilla":
					t.ok(not db.leccion(d.id).is_empty(), "%s: lección %s existe" % [id, d.id])
					t.eq(str(db.leccion(d.id).get("sala", "")), id, "%s está en la sala de su currículo" % d.id)
					t.ok(not tablillas.has(d.id), "tablilla %s colocada una sola vez" % d.id)
					tablillas[d.id] = true
				"sello":
					t.ok(not db.sello(d.id).is_empty(), "%s: sello %s existe" % [id, d.id])
					sellos[d.id] = true
				"enemy":
					t.ok(ResourceLoader.exists("res://scripts/enemies/%s.gd" % d.kind), "%s: enemigo %s" % [id, d.kind])
					t.ok(not db.enemy(d.kind).is_empty(), "%s: ficha de bestiario %s" % [id, d.kind])
				"pickup":
					var val: String = str(d.get("value", d.get("ability", d.get("amulet", d.get("amuleto", "")))))
					if str(d.get("kind", "")) in ["charm", "amulet", "amuleto"]:
						t.ok(not db.amuleto(val).is_empty(), "%s: amuleto %s" % [id, val])
					if str(d.get("kind", "")) == "ability":
						t.ok(not db.habilidad(val).is_empty(), "%s: habilidad %s" % [id, val])
		room.free()
	t.eq(tablillas.size(), 205, "las 205 lecciones están colocadas")
	t.eq(sellos.size(), 28, "los 28 sellos están colocados")


func test_hub_has_start_spawn() -> void:
	var room := _room("hub_plaza")
	t.ok(room.entity_defs().any(func(o): return o.id == "inicio"), "punto de inicio")
	t.ok(room.entity_defs().any(func(o): return o.id == "banco"), "banco del hub")
	room.free()


func test_linked_entities_exist() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		var ids := room.entity_defs().map(func(o): return o.id)
		for d in room.entity_defs():
			var refs: Array = []
			if d.has("target"):
				refs.append(d.target)
			refs.append_array(d.get("targets", []))
			for r in refs:
				t.ok(r in ids, "%s: %s referencia a %s" % [id, d.id, r])
		room.free()


func test_rooms_build_in_tree() -> void:
	for id in ROOM_IDS:
		var room := _room(id)
		t.add_child(room)
		room.build()
		t.ok(room.get_child_count() > 3, "%s construye nodos" % id)
		t.ok(room.entities.size() > 0, "%s tiene entidades" % id)
		await t.get_tree().process_frame
		room.queue_free()
		await t.get_tree().process_frame


func test_las_compuertas_de_las_arenas_empiezan_abiertas() -> void:
	# Si empiezan cerradas, bloquean la entrada antes de poder llegar al jefe
	# (bug real: z1/z2/z8/z9/hub_sanctum se crearon sin start_open/persist:false).
	for room_id: String in WorldMap.ROOMS.keys():
		var inst: RoomBase = load("res://rooms/%s.gd" % room_id).new()
		for ch: String in inst.legend():
			var d: Dictionary = inst.legend()[ch]
			if str(d.get("type", "")) == "gate" and str(d.get("id", "")).begins_with("gate_"):
				t.ok(bool(d.get("start_open", false)), "%s.%s: empieza abierta" % [room_id, d.id])
				t.ok(not bool(d.get("persist", true)), "%s.%s: no persiste (se cierra de nuevo cada visita)" % [room_id, d.id])
		inst.free()
