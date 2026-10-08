class_name RoomBase
extends Node2D
## Base de todas las salas. Cada sala define un layout ASCII y una leyenda
## de entidades; `build()` genera colisiones, terreno, fondo y entidades.
##
## Caracteres: `#` sólido · `=` plataforma de un sentido · `^` pinchos ·
## `.` vacío · cualquier otro carácter = entidad definida en `legend()`.

const TILE := 64

const ENTITY_SCRIPTS := {
	"door": "res://scripts/objects/door.gd",
	"bench": "res://scripts/objects/bench.gd",
	"tablilla": "res://scripts/objects/tablilla.gd",
	"sello": "res://scripts/objects/sello_gate.gd",
	"anchor": "res://scripts/objects/anchor.gd",
	"click_node": "res://scripts/objects/click_node.gd",
	"hover_node": "res://scripts/objects/hover_node.gd",
	"hover_platform": "res://scripts/objects/hover_platform.gd",
	"gate": "res://scripts/objects/gate.gd",
	"chest": "res://scripts/objects/cache_chest.gd",
	"fake_wall": "res://scripts/objects/fake_wall.gd",
	"pickup": "res://scripts/objects/pickup.gd",
	"npc": "res://scripts/objects/npc.gd",
	"portal": "res://scripts/objects/portal.gd",
	"lamp": "res://scripts/objects/lamp.gd",
	"enemy": "res://scripts/enemies/enemy_spawner.gd",
	"boss": "res://scripts/boss/boss_arena.gd",
	"shade": "res://scripts/enemies/conflicto_merge.gd",
	"sign": "res://scripts/objects/sign.gd",
	"decor": "res://scripts/objects/decor.gd",
	"flex": "res://scripts/objects/flex_container.gd",
	"promesa": "res://scripts/objects/promise_fountain.gd",
	"promise_all": "res://scripts/objects/promise_all_gate.gd",
	"pipe": "res://scripts/objects/data_pipe.gd",
	"paginador": "res://scripts/objects/paginador.gd",
	"atril": "res://scripts/objects/atril.gd",
	"palanca": "res://scripts/objects/palanca.gd",
	"autorizador": "res://scripts/objects/autorizador.gd",
	"lector": "res://scripts/objects/lector.gd",
	"puente_token": "res://scripts/objects/puente_token.gd",
	"rest_terminal": "res://scripts/objects/rest_terminal.gd",
	"layer_gate": "res://scripts/objects/layer_gate.gd",
	"shard_platform": "res://scripts/objects/shard_platform.gd",
	"binding_node": "res://scripts/objects/binding_node.gd",
	"linked_platform": "res://scripts/objects/linked_platform.gd",
	"clean_gate": "res://scripts/objects/clean_gate.gd",
	"pod_launcher": "res://scripts/objects/pod_launcher.gd",
	"container_box": "res://scripts/objects/container_box.gd",
	"pipeline_gate": "res://scripts/objects/pipeline_gate.gd",
	"inspector_prism": "res://scripts/objects/inspector_prism.gd",
	"assert_node": "res://scripts/objects/assert_node.gd",
	"owasp_barrier": "res://scripts/objects/owasp_barrier.gd",
}

var room_id := ""
var zone := 3
var display_name := ""
var area_title := ""  # si no está vacío, se muestra al entrar por primera vez

var rows: PackedStringArray
var entities := {}  # id → Node
var terrain: TerrainRenderer
var entity_layer: Node2D


# --- Para sobrescribir -------------------------------------------------------

func layout() -> PackedStringArray:
	return PackedStringArray()


func legend() -> Dictionary:
	return {}


func theme_name() -> String:
	return "forest"


func music() -> String:
	return "forest"


## Llamado al terminar de construir la sala.
func on_built() -> void:
	pass


# --- Consultas -------------------------------------------------------------------

func size_tiles() -> Vector2i:
	var r := layout()
	return Vector2i(r[0].length() if r.size() > 0 else 0, r.size())


func size_px() -> Vector2:
	return Vector2(size_tiles()) * TILE


func theme() -> Dictionary:
	return Themes.get_theme(theme_name())


func cell_bottom_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE * 0.5, (cell.y + 1) * TILE)


func get_entity(id: String) -> Node:
	return entities.get(id)


func flag_key(id: String) -> String:
	return "%s:%s" % [room_id, id]


## Lista de definiciones de entidades con su celda (útil para pruebas).
func entity_defs() -> Array:
	var out := []
	var leg := legend()
	var r := layout()
	for y in r.size():
		for x in r[y].length():
			var c := r[y][x]
			if c in "#=^. ":
				continue
			if not leg.has(c):
				out.append({"type": "_unknown", "char": c, "cell": Vector2i(x, y)})
				continue
			var def: Dictionary = leg[c].duplicate(true)
			def["cell"] = Vector2i(x, y)
			if not def.has("id"):
				def["id"] = "%s_%d_%d" % [def.get("type", "e"), x, y]
			out.append(def)
	return out


## Posición de aparición para una puerta o entidad.
func get_spawn(id: String) -> Vector2:
	var node := get_entity(id)
	if node == null:
		push_warning("Sala %s: punto de aparición '%s' no existe" % [room_id, id])
		return Vector2(TILE * 3, TILE * 3)
	if node.has_method("spawn_position"):
		return node.spawn_position()
	return node.global_position


# --- Construcción ------------------------------------------------------------------

func build() -> void:
	rows = layout()
	var th := theme()
	var s := size_tiles()
	var seed_value := hash(room_id)

	var backdrop := Backdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	backdrop.build(th, size_px(), seed_value)

	terrain = TerrainRenderer.new()
	terrain.name = "Terrain"
	terrain.z_index = 0
	add_child(terrain)
	terrain.setup(rows, th, seed_value)
	if th.get("water", false):
		var water := WaterRenderer.new()
		water.name = "Water"
		add_child(water)
		water.setup(rows, th)

	_build_collision(s)
	_build_hazards(s)

	entity_layer = Node2D.new()
	entity_layer.name = "Entities"
	entity_layer.z_index = 5
	add_child(entity_layer)
	for def in entity_defs():
		_spawn_entity(def)

	# Zona de muerte bajo la sala.
	var kill := Hazard.new()
	kill.pogo = false
	kill.add_rect(Rect2(-TILE * 4, s.y * TILE + 120, (s.x + 8) * TILE, 200))
	add_child(kill)

	for e in entities.values():
		if e.has_method("on_room_ready"):
			e.on_room_ready(self)
	on_built()


func _build_collision(s: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.name = "Solid"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	# Rectángulos fusionados: primero por filas, luego verticalmente.
	var open_runs := {}  # Vector2i(x0, x1) → Rect2i
	var rects: Array[Rect2i] = []
	for y in s.y:
		var row_runs := {}
		var x := 0
		while x < s.x:
			if rows[y][x] == "#":
				var x0 := x
				while x < s.x and rows[y][x] == "#":
					x += 1
				row_runs[Vector2i(x0, x)] = true
			else:
				x += 1
		var next_open := {}
		for key in row_runs.keys():
			if open_runs.has(key):
				var r: Rect2i = open_runs[key]
				r.size.y += 1
				next_open[key] = r
			else:
				next_open[key] = Rect2i(key.x, y, key.y - key.x, 1)
		for key in open_runs.keys():
			if not next_open.has(key):
				rects.append(open_runs[key])
		open_runs = next_open
	for key in open_runs.keys():
		rects.append(open_runs[key])
	for r in rects:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(r.size) * TILE
		cs.shape = shape
		cs.position = Vector2(r.position) * TILE + shape.size * 0.5
		body.add_child(cs)
	# Plataformas de un sentido.
	for y in s.y:
		var x := 0
		while x < s.x:
			if rows[y][x] == "=":
				var x0 := x
				while x < s.x and rows[y][x] == "=":
					x += 1
				var cs := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - x0) * TILE, 20)
				cs.shape = shape
				cs.one_way_collision = true
				cs.position = Vector2(x0 * TILE + shape.size.x * 0.5, y * TILE + 10)
				body.add_child(cs)
			else:
				x += 1


func _build_hazards(s: Vector2i) -> void:
	var hz := Hazard.new()
	hz.name = "Spikes"
	var any := false
	for y in s.y:
		var x := 0
		while x < s.x:
			if rows[y][x] == "^":
				var x0 := x
				while x < s.x and rows[y][x] == "^":
					x += 1
				hz.add_rect(Rect2(x0 * TILE + 6, y * TILE + 30, (x - x0) * TILE - 12, 34))
				any = true
			else:
				x += 1
	if any:
		add_child(hz)
	else:
		hz.free()


func _spawn_entity(def: Dictionary) -> void:
	var type: String = def.get("type", "")
	if not ENTITY_SCRIPTS.has(type):
		push_error("Sala %s: tipo de entidad desconocido '%s' en %s" % [room_id, type, def.cell])
		return
	var script: GDScript = load(ENTITY_SCRIPTS[type])
	var node: Node2D = script.new()
	node.name = str(def.id).replace(":", "_")
	entity_layer.add_child(node)
	node.global_position = cell_bottom_center(def.cell)
	if node.has_method("setup"):
		node.setup(self, def)
	entities[def.id] = node


func add_runtime_entity(id: String, node: Node2D) -> void:
	entity_layer.add_child(node)
	entities[id] = node
