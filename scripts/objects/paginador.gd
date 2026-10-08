extends Node2D
## Estantería paginada: una lista de plataformas de la que solo existen las
## de la página actual. Los atriles cambian la página.
##
## Definición:
##   {"type": "paginador", "id": ..., "tam": elementos por página,
##    "items": [[dx, dy, ancho], ...] (tiles relativos a la celda; dy=0 es la
##    superficie del suelo de la celda), "pagina": página inicial (desde 1),
##    "estilo": "odata" | "jsonapi", "recurso": "estantes", "persistente": bool}

signal page_changed(page: int)

const TILE := 64
const THICK := 22.0

var room: RoomBase
var def: Dictionary
var page_size := 3
var page := 1
var rects: Array[Rect2] = []
var bodies: Array[StaticBody2D] = []
var t := 0.0
var flash := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	add_to_group("paginador")
	page_size = maxi(1, int(def.get("tam", 3)))
	z_index = 2
	for it in def.get("items", []):
		var r := Rect2(Vector2(float(it[0]) * TILE - TILE * 0.5, float(it[1]) * TILE), Vector2(float(it[2]) * TILE, THICK))
		rects.append(r)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.get_center()
		cs.one_way_collision = true
		body.add_child(cs)
		add_child(body)
		bodies.append(body)
	var saved = GameState.get_flag(room.flag_key(def.id))
	var start := int(def.get("pagina", 1))
	if persistent() and (saved is int or saved is float):
		start = int(saved)
	set_page(start, false)


func persistent() -> bool:
	return bool(def.get("persistente", true))


func page_count() -> int:
	return maxi(1, ceili(float(rects.size()) / page_size))


## Índices de los elementos visibles en una página (desde 1).
func items_on_page(p: int) -> Array:
	var out := []
	var first := (p - 1) * page_size
	for i in range(first, mini(first + page_size, rects.size())):
		out.append(i)
	return out


func is_item_visible(i: int) -> bool:
	return i in items_on_page(page)


func set_page(p: int, animated := true) -> void:
	page = clampi(p, 1, page_count())
	var shown := items_on_page(page)
	for i in bodies.size():
		(bodies[i].get_child(0) as CollisionShape2D).set_deferred("disabled", not (i in shown))
	if persistent() and room:
		GameState.set_flag(room.flag_key(def.id), page)
	_fix_player_safe_position(shown)
	if animated:
		flash = 1.0
		AudioManager.play_sfx("node_on", 0.08)
	page_changed.emit(page)


## Si el punto de reaparición del jugador estaba sobre una balda que acaba de
## desaparecer, lo mueve a donde está ahora (junto al atril, en suelo firme).
func _fix_player_safe_position(shown: Array) -> void:
	if not is_inside_tree():
		return
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	for i in rects.size():
		if i in shown:
			continue
		var r := Rect2(global_position + rects[i].position, rects[i].size).grow(40.0)
		if r.has_point(p._safe_pos):
			p._safe_pos = p.global_position if p.is_on_floor() else global_position
			return


func next_page() -> void:
	set_page(page % page_count() + 1)


func previous_page() -> void:
	set_page((page - 2 + page_count()) % page_count() + 1)


func query_text(p := -1) -> String:
	if p < 0:
		p = page
	var resource := str(def.get("recurso", "estantes"))
	if str(def.get("estilo", "odata")) == "jsonapi":
		return "GET /%s?page[number]=%d&page[size]=%d" % [resource, p, page_size]
	return "GET /%s?$top=%d&$skip=%d" % [resource, page_size, (p - 1) * page_size]


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var font := UITheme.mono_font()
	var gold := Color(2.2, 1.6, 0.7)
	var shown := items_on_page(page)
	for i in rects.size():
		var r := rects[i]
		if i in shown:
			# Balda de estantería con lomos de libros.
			draw_rect(r, Color(0.3, 0.18, 0.1))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 5)), Color(gold, 0.9).lerp(Color(3, 3, 3), flash))
			var x := r.position.x + 6
			var k := 0
			while x < r.end.x - 10:
				var w := 8.0 + (k * 7 % 5)
				var h := 26.0 + (k * 13 % 14)
				var cols := [Color(0.55, 0.2, 0.15), Color(0.2, 0.35, 0.5), Color(0.5, 0.42, 0.2), Color(0.25, 0.4, 0.28)]
				draw_rect(Rect2(Vector2(x, r.position.y - h), Vector2(w, h)), cols[k % cols.size()])
				x += w + 2
				k += 1
			draw_string(font, r.position + Vector2(4, 18), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.8, 1.4, 0.8))
		else:
			draw_rect(r, Color(0.9, 0.7, 0.4, 0.15), false, 1.5)
			draw_string(font, r.position + Vector2(4, 18), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.8, 0.6, 0.25))
	# Consulta y número de página.
	var text := query_text()
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var pos := Vector2(-TILE * 0.5, -TILE * 3.2)
	draw_rect(Rect2(pos + Vector2(-8, -22), Vector2(ts.x + 16, 56)), Color(0, 0, 0, 0.55))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(2.0, 1.6, 0.8).lerp(Color(3, 3, 3), flash))
	draw_string(font, pos + Vector2(0, 24), "página %d de %d" % [page, page_count()], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.4, 1.2, 0.9, 0.8))
