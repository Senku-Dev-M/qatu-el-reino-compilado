class_name MapView
extends Control
## Mapa superpuesto mientras se mantiene la tecla de mapa.
##
## Cada sala visitada se dibuja con su terreno real (bordes de roca,
## plataformas y pinchos) a partir de su layout; las salas vecinas sin visitar
## aparecen como contornos con «?». Encima van los pasillos entre puertas, los
## iconos (bancos, El Manual, sellos, tablillas, habilidades, jefe, salidas) y
## la posición del jugador.

const MIN_SCALE := 2.4
const MAX_SCALE := 9.0

## Texturas del terreno de cada sala (1 píxel = 1 tile).
static var _terrain_cache := {}
static var _theme_cache := {}

var title: Label
var subtitle: Label
var note: Label
var t := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false


func _ready() -> void:
	title = UITheme.label("", 48, UITheme.GOLD, true)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-450, 36)
	title.custom_minimum_size = Vector2(900, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	subtitle = UITheme.label("", 24, UITheme.DIM)
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-450, 104)
	subtitle.custom_minimum_size = Vector2(900, 0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	note = UITheme.label("", 30, UITheme.DIM)
	note.set_anchors_preset(Control.PRESET_CENTER)
	note.custom_minimum_size = Vector2(1000, 0)
	note.position = Vector2(-500, -40)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)


# --- Qué mapa hay disponible ------------------------------------------------------------

func _zone() -> int:
	var room := RoomRouter.current_room
	return room.zone if room else 0


## Bandera que activa el mapa de una zona y dónde se consigue.
static func map_source(zone: int) -> Dictionary:
	if zone == 3:
		return {"flag": "tienda:mapa", "donde": "Se lo puedes comprar a La Depuradora."}
	for id: String in WorldMap.ROOMS.keys():
		if int(WorldMap.ROOMS[id].zone) != zone:
			continue
		for d: Dictionary in WorldMap.info(id).get("defs", []):
			if d.get("type") == "pickup" and d.get("kind") == "map":
				return {"flag": "%s:%s" % [id, d.id], "donde": "Búscalo en «%s»." % WorldMap.info(id).name}
	return {}


static func zone_has_map(zone: int) -> bool:
	if zone == 0 or zone == 10:
		return true
	var src := map_source(zone)
	return not src.is_empty() and bool(GameState.get_flag(str(src.flag)))


func has_map() -> bool:
	return zone_has_map(_zone())


func set_open(open: bool) -> void:
	visible = open
	if not open:
		return
	var zone := _zone()
	title.text = "Plaza de Qatu" if zone == 0 else str(ContentDB.zona(zone).get("nombre", "Qatu"))
	subtitle.text = _progress_text(zone)
	if has_map():
		note.text = ""
	else:
		note.text = "No tienes el mapa de esta zona.\n" + str(map_source(zone).get("donde", ""))
	queue_redraw()


func _zone_rooms(zone: int) -> Array:
	var ids := []
	for id: String in WorldMap.ROOMS.keys():
		if int(WorldMap.ROOMS[id].zone) == zone:
			ids.append(id)
	return ids


func _progress_text(zone: int) -> String:
	var ids := _zone_rooms(zone)
	var visited := 0
	var tabl := 0
	var tabl_read := 0
	var sellos := 0
	var sellos_ok := 0
	for id: String in ids:
		if id in GameState.data.rooms_visited:
			visited += 1
		for d: Dictionary in WorldMap.info(id).get("defs", []):
			if d.get("type") == "tablilla":
				tabl += 1
				if d.id in GameState.data.tablillas:
					tabl_read += 1
			elif d.get("type") == "sello":
				sellos += 1
				if d.id in GameState.data.sellos:
					sellos_ok += 1
	var parts := ["Salas %d/%d" % [visited, ids.size()]]
	if tabl > 0:
		parts.append("Lecciones %d/%d" % [tabl_read, tabl])
	if sellos > 0:
		parts.append("Sellos %d/%d" % [sellos_ok, sellos])
	return "   ·   ".join(parts)


# --- Texturas de terreno ----------------------------------------------------------------

static func theme_of(room_id: String) -> String:
	if not _theme_cache.has(room_id):
		var room: RoomBase = load("res://rooms/%s.gd" % room_id).new()
		_theme_cache[room_id] = room.theme_name()
		room.free()
	return _theme_cache[room_id]


static func _ldr(c: Color) -> Color:
	return Color(minf(c.r, 1.0), minf(c.g, 1.0), minf(c.b, 1.0), minf(c.a, 1.0))


static func terrain_texture(room_id: String) -> Texture2D:
	if _terrain_cache.has(room_id):
		return _terrain_cache[room_id]
	var path := "res://rooms/%s.gd" % room_id
	if not ResourceLoader.exists(path):
		return null
	var room: RoomBase = load(path).new()
	var rows := room.layout()
	var th := Themes.get_theme(room.theme_name())
	room.free()
	var h := rows.size()
	var w := rows[0].length() if h > 0 else 0
	if w == 0:
		return null
	var rim := _ldr(th.get("rim", Color(0.8, 0.7, 0.5)))
	var fill := rim.darkened(0.6)
	var edge := rim.lerp(Color(0.95, 0.9, 0.8), 0.25)
	var oneway := rim.lerp(Color.WHITE, 0.55)
	var spike := Color(0.95, 0.3, 0.35)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var c := rows[y][x]
			if c == "#":
				var border := false
				for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + o.x
					var ny := y + o.y
					if nx >= 0 and ny >= 0 and nx < w and ny < h and rows[ny][nx] != "#":
						border = true
				img.set_pixel(x, y, edge if border else fill)
			elif c == "=":
				img.set_pixel(x, y, oneway)
			elif c == "^":
				img.set_pixel(x, y, spike)
	var tex := ImageTexture.create_from_image(img)
	_terrain_cache[room_id] = tex
	return tex


# --- Dibujo -----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if visible:
		t += delta
		queue_redraw()


func _draw() -> void:
	_draw_backdrop()
	if not has_map():
		return
	var room := RoomRouter.current_room
	if room == null:
		return
	var zone := room.zone
	var ids := _zone_rooms(zone)
	var visited: Array = GameState.data.rooms_visited
	var known := {}
	for id: String in ids:
		if id in visited or id == room.room_id:
			known[id] = true
	for id: String in known.keys():
		for n: String in WorldMap.neighbors(id):
			if WorldMap.ROOMS.has(n) and int(WorldMap.ROOMS[n].zone) == zone and not known.has(n):
				known[n] = false
	var bounds := Rect2()
	var first := true
	for id: String in known.keys():
		var r := WorldMap.rect(id)
		bounds = r if first else bounds.merge(r)
		first = false
	if first:
		return
	var area := Rect2(Vector2(110, 170), size - Vector2(220, 330))
	var scale := minf(area.size.x / maxf(bounds.size.x, 1.0), area.size.y / maxf(bounds.size.y, 1.0))
	scale = clampf(scale, MIN_SCALE, MAX_SCALE)
	var origin := area.get_center() - bounds.get_center() * scale
	# Si el mapa no cabe, se centra en la sala actual.
	if bounds.size.x * scale > area.size.x or bounds.size.y * scale > area.size.y:
		origin = area.get_center() - WorldMap.rect(room.room_id).get_center() * scale
	_draw_corridors(known, origin, scale)
	for id: String in known.keys():
		var r := WorldMap.rect(id)
		var sr := Rect2(origin + r.position * scale, r.size * scale)
		if known[id]:
			_draw_room(id, sr, id == room.room_id)
		else:
			_draw_unknown(sr)
	var screen_rects := {}
	for id: String in known.keys():
		var r := WorldMap.rect(id)
		screen_rects[id] = Rect2(origin + r.position * scale, r.size * scale)
	var used_labels: Array[Rect2] = []
	for id: String in known.keys():
		if known[id]:
			var sr: Rect2 = screen_rects[id]
			_draw_room_markers(id, sr, scale)
			_draw_room_name(id, sr, id == room.room_id, screen_rects, used_labels)
	_draw_player(room, origin, scale)
	_draw_legend()


func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.014, 0.02, 0.985))
	# Marco doble con esquinas, como un pergamino oscuro.
	var frame := Rect2(Vector2(40, 24), size - Vector2(80, 48))
	draw_rect(frame, Color(0.93, 0.78, 0.45, 0.35), false, 2.0)
	draw_rect(frame.grow(-10), Color(0.93, 0.78, 0.45, 0.14), false, 1.0)
	for corner: Vector2 in [frame.position, Vector2(frame.end.x, frame.position.y), frame.end, Vector2(frame.position.x, frame.end.y)]:
		var pts := PackedVector2Array([corner + Vector2(0, -12), corner + Vector2(12, 0), corner + Vector2(0, 12), corner + Vector2(-12, 0)])
		draw_colored_polygon(pts, Color(0.93, 0.78, 0.45, 0.6))
	# Rejilla tenue.
	var step := 64.0
	for i in int(frame.size.x / step):
		var x := frame.position.x + 12.0 + i * step
		draw_line(Vector2(x, frame.position.y + 12), Vector2(x, frame.end.y - 12), Color(1, 1, 1, 0.02), 1.0)
	for j in int(frame.size.y / step):
		var y := frame.position.y + 12.0 + j * step
		draw_line(Vector2(frame.position.x + 12, y), Vector2(frame.end.x - 12, y), Color(1, 1, 1, 0.02), 1.0)


## Punto de una puerta en coordenadas de mapa (tiles globales), pegado al borde.
func _door_point(room_id: String, d: Dictionary) -> Vector2:
	var r := WorldMap.rect(room_id)
	var cell: Vector2i = d.cell
	var p := Vector2(cell) + Vector2(0.5, 0.0)
	if cell.x <= 0:
		p.x = 0.0
	elif cell.x >= int(r.size.x) - 1:
		p.x = r.size.x
	return r.position + p


func _draw_corridors(known: Dictionary, origin: Vector2, scale: float) -> void:
	var done := {}
	for id: String in known.keys():
		if not known[id]:
			continue
		for d: Dictionary in WorldMap.info(id).get("doors", []):
			var to := str(d.get("to", ""))
			if d.get("type") != "door" or not known.has(to):
				continue
			var key := [id, to]
			key.sort()
			if done.has(str(key)):
				continue
			done[str(key)] = true
			var a := origin + _door_point(id, d) * scale
			var other := {}
			for d2: Dictionary in WorldMap.info(to).get("doors", []):
				if str(d2.get("to", "")) == id:
					other = d2
			var bp := WorldMap.rect(to).get_center()
			if not other.is_empty():
				bp = _door_point(to, other)
			var b := origin + bp * scale
			var col := Color(0.93, 0.78, 0.45, 0.85 if known[to] else 0.35)
			var mid := b
			if absf(a.y - b.y) > 2.0 and absf(a.x - b.x) > 2.0:
				mid = Vector2(b.x, a.y)
			draw_line(a, mid, Color(0, 0, 0, 0.6), 9.0)
			draw_line(mid, b, Color(0, 0, 0, 0.6), 9.0)
			draw_line(a, mid, col, 4.0)
			draw_line(mid, b, col, 4.0)
			draw_circle(a, 5.0, col)
			draw_circle(b, 5.0, col)


func _draw_room(id: String, sr: Rect2, current: bool) -> void:
	var th := Themes.get_theme(theme_of(id))
	var bg := _ldr(th.get("sky_bottom", Color(0.1, 0.1, 0.12))).lerp(Color(0.05, 0.05, 0.06), 0.35)
	draw_rect(Rect2(sr.position + Vector2(6, 8), sr.size), Color(0, 0, 0, 0.5))
	draw_rect(sr, bg)
	var tex := terrain_texture(id)
	if tex:
		draw_texture_rect(tex, sr, false)
	if current:
		var pulse := 0.6 + 0.4 * sin(t * 4.0)
		draw_rect(sr.grow(6), Color(0.55, 0.95, 0.9, 0.18 * pulse), false, 10.0)
		draw_rect(sr.grow(2), Color(0.55, 0.95, 0.9, 0.9), false, 3.0)
	else:
		draw_rect(sr.grow(1), Color(0.93, 0.78, 0.45, 0.55), false, 2.0)


func _draw_unknown(sr: Rect2) -> void:
	draw_rect(sr, Color(0.5, 0.5, 0.5, 0.05))
	var col := Color(0.7, 0.7, 0.68, 0.45)
	var corners := [sr.position, Vector2(sr.end.x, sr.position.y), sr.end, Vector2(sr.position.x, sr.end.y)]
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		var n := maxi(2, int(a.distance_to(b) / 14.0))
		for i in range(0, n, 2):
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 2.0)
	var font := UITheme.title_font()
	var fs := int(clampf(sr.size.y * 0.5, 20, 48))
	var w := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, sr.get_center() + Vector2(-w * 0.5, fs * 0.35), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_room_name(id: String, sr: Rect2, current: bool, rects: Dictionary, used: Array[Rect2]) -> void:
	var font := UITheme.title_font()
	var name: String = WorldMap.info(id).name
	var fs := 18
	while fs > 12 and font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > sr.size.x + 30.0:
		fs -= 1
	var w := minf(font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, sr.size.x + 30.0)
	# Debajo de la sala; si choca con otra sala u otro nombre, encima; si no, dentro.
	var candidates := [sr.end.y + 8.0, sr.position.y - 34.0, sr.position.y + 6.0]
	var box := Rect2()
	for top: float in candidates:
		box = Rect2(Vector2(sr.get_center().x - w * 0.5 - 10.0, top), Vector2(w + 20.0, 26.0))
		var clash := false
		for other: String in rects.keys():
			if other != id and (rects[other] as Rect2).intersects(box):
				clash = true
		for u in used:
			if u.intersects(box):
				clash = true
		if not clash:
			break
	used.append(box)
	draw_rect(box, Color(0.01, 0.012, 0.02, 0.88))
	draw_string(font, box.position + Vector2(10, 19), name, HORIZONTAL_ALIGNMENT_LEFT, w, fs, UITheme.CYAN if current else Color(0.9, 0.86, 0.74))


# --- Iconos -----------------------------------------------------------------------------

func _icon_bench(p: Vector2, s := 1.0) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -9) * s, p + Vector2(9, 0) * s, p + Vector2(0, 9) * s, p + Vector2(-9, 0) * s]), UITheme.GOLD)
	draw_circle(p, 3.0 * s, Color(0.2, 0.15, 0.05))


func _icon_tablilla(p: Vector2, read: bool, s := 1.0) -> void:
	var col := Color(0.55, 0.95, 0.9, 0.5) if read else UITheme.CYAN
	if not read:
		draw_circle(p, (11.0 + 3.0 * sin(t * 5.0)) * s, Color(0.55, 0.95, 0.9, 0.2))
	var r := Rect2(p - Vector2(5, 7) * s, Vector2(10, 14) * s)
	draw_rect(r, Color(0.05, 0.08, 0.08))
	draw_rect(r, col, false, 2.0)
	draw_line(p + Vector2(-2, -2) * s, p + Vector2(2, -2) * s, col, 1.5)
	draw_line(p + Vector2(-2, 2) * s, p + Vector2(2, 2) * s, col, 1.5)


func _icon_sello(p: Vector2, done: bool, s := 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(p + Vector2.RIGHT.rotated(TAU * i / 6.0 + PI / 6.0) * 10.0 * s)
	var col := Color(0.5, 0.95, 0.55) if done else Color(0.9, 0.5, 0.9)
	draw_colored_polygon(pts, Color(col, 0.35))
	pts.append(pts[0])
	draw_polyline(pts, col, 2.0)


func _icon_manual(p: Vector2, s := 1.0) -> void:
	draw_rect(Rect2(p + Vector2(-9, -6) * s, Vector2(8, 12) * s), Color(0.85, 0.85, 0.8))
	draw_rect(Rect2(p + Vector2(1, -6) * s, Vector2(8, 12) * s), Color(0.85, 0.85, 0.8))
	draw_line(p + Vector2(0, -7) * s, p + Vector2(0, 7) * s, Color(0.4, 0.6, 0.95), 2.0)


func _icon_ability(p: Vector2, taken: bool, s := 1.0) -> void:
	var col := Color(0.5, 1.0, 0.95, 0.4) if taken else Color(0.5, 1.0, 0.95)
	var spin := 0.0 if taken else t
	for i in 8:
		var r := (13.0 if i % 2 == 0 else 7.0) * s
		draw_line(p, p + Vector2.RIGHT.rotated(TAU * i / 8.0 + spin) * r, col, 2.0)
	draw_circle(p, 4.0 * s, col)


func _icon_boss(p: Vector2, defeated: bool, s := 1.0) -> void:
	var col := Color(0.6, 0.6, 0.6) if defeated else Color(0.95, 0.35, 0.35)
	draw_circle(p, 12.0 * s, Color(col, 0.25))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 4) * s, p + Vector2(-10, -6) * s, p + Vector2(-5, -1) * s,
		p + Vector2(0, -9) * s, p + Vector2(5, -1) * s, p + Vector2(10, -6) * s, p + Vector2(10, 4) * s]), col)
	if defeated:
		draw_line(p + Vector2(-12, -12) * s, p + Vector2(12, 12) * s, Color(0.9, 0.9, 0.9), 2.0)


func _icon_map(p: Vector2, s := 1.0) -> void:
	draw_rect(Rect2(p - Vector2(9, 6) * s, Vector2(18, 12) * s), Color(0.9, 0.8, 0.6))
	draw_polyline(PackedVector2Array([p + Vector2(-6, 2) * s, p + Vector2(-1, -3) * s, p + Vector2(3, 2) * s, p + Vector2(7, -3) * s]), Color(0.6, 0.2, 0.15), 1.5)


func _icon_exit(p: Vector2, dir: float, s := 1.0) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(10 * dir, 0) * s, p + Vector2(-4 * dir, -8) * s, p + Vector2(-4 * dir, 8) * s]), UITheme.GOLD)


func _icon_shop(p: Vector2, s := 1.0) -> void:
	draw_circle(p + Vector2(0, 2) * s, 8.0 * s, UITheme.GOLD)
	draw_rect(Rect2(p + Vector2(-3, -9) * s, Vector2(6, 5) * s), UITheme.GOLD)


func _draw_room_markers(id: String, sr: Rect2, scale: float) -> void:
	var semantic := GameState.is_charm_equipped("semantica")
	var s := clampf(scale / 5.0, 0.8, 1.4)
	var zone := int(WorldMap.ROOMS[id].zone)
	var font := UITheme.title_font()
	for d: Dictionary in WorldMap.info(id).defs:
		var cell: Vector2i = d.cell
		var p: Vector2 = sr.position + (Vector2(cell) + Vector2(0.5, 0.5)) * scale
		match str(d.get("type", "")):
			"bench":
				_icon_bench(p, s)
			"tablilla":
				var read: bool = d.id in GameState.data.tablillas
				# Las pendientes solo se marcan con el amuleto Semántica.
				if read or semantic:
					_icon_tablilla(p, read, s)
			"sello":
				var done: bool = d.id in GameState.data.sellos
				if done or semantic:
					_icon_sello(p, done, s)
			"npc":
				match str(d.get("who", "")):
					"manual":
						_icon_manual(p, s)
					"depuradora":
						_icon_shop(p, s)
			"pickup":
				var taken := bool(GameState.get_flag("%s:%s" % [id, d.id]))
				match str(d.get("kind", "")):
					"ability":
						_icon_ability(p, taken, s)
					"map":
						if not taken:
							_icon_map(p, s)
			"boss":
				_icon_boss(p + Vector2(0, -scale * 2.0), bool(GameState.get_flag("jefe:" + str(d.get("kind", "")))), s)
			"portal":
				_icon_exit(p, 1.0, s)
			"door":
				var to := str(d.get("to", ""))
				if WorldMap.ROOMS.has(to) and int(WorldMap.ROOMS[to].zone) != zone:
					var dir := -1.0 if cell.x <= 0 else 1.0
					_icon_exit(p + Vector2(dir * 14.0, 0), dir, s)
					var tz := int(WorldMap.ROOMS[to].zone)
					var label := "Plaza de Qatu" if tz == 0 else str(ContentDB.zona(tz).get("nombre", ""))
					var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
					# Encima de la flecha, para no tapar el nombre de la sala.
					var lp := p + Vector2(dir * 14.0 - w * 0.5, -18.0)
					lp.x = clampf(lp.x, 60.0, size.x - 60.0 - w)
					draw_rect(Rect2(lp + Vector2(-6, -16), Vector2(w + 12, 22)), Color(0.01, 0.012, 0.02, 0.85))
					draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.93, 0.78, 0.45, 0.9))


func _draw_player(room: RoomBase, origin: Vector2, scale: float) -> void:
	var player: Node2D = RoomRouter.world.player if RoomRouter.world else null
	if player == null or not WorldMap.ROOMS.has(room.room_id):
		return
	var r := WorldMap.rect(room.room_id)
	var p := origin + (r.position + player.global_position / 64.0 + Vector2(0, -0.7)) * scale
	var pulse := 1.0 + 0.3 * sin(t * 5.0)
	draw_circle(p, 18 * pulse, Color(0.5, 1.0, 1.0, 0.18))
	draw_circle(p, 9, Color(0.02, 0.05, 0.06))
	draw_circle(p, 7, Color(1, 1, 1))
	var facing := 1.0
	if player is Player:
		facing = (player as Player).facing
	draw_colored_polygon(PackedVector2Array([p + Vector2(17 * facing, 0), p + Vector2(10 * facing, -6), p + Vector2(10 * facing, 6)]), UITheme.CYAN)


func _draw_legend() -> void:
	var font := UITheme.title_font()
	var items := [["bench", "Banco"], ["manual", "El Manual"], ["tablilla", "Tablilla"], ["sello", "Sello"],
		["ability", "Habilidad"], ["boss", "Jefe"], ["exit", "Salida"], ["player", "Tú"]]
	var fs := 20
	var total := 0.0
	for it: Array in items:
		total += 34.0 + font.get_string_size(str(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 26.0
	var x := size.x * 0.5 - total * 0.5
	var y := size.y - 84.0
	var box := Rect2(Vector2(x - 20, y - 26), Vector2(total + 40, 44))
	draw_rect(box, Color(0.01, 0.012, 0.02, 0.85))
	draw_rect(box, Color(0.93, 0.78, 0.45, 0.3), false, 1.0)
	for it: Array in items:
		var p := Vector2(x + 12, y - 4)
		match str(it[0]):
			"bench": _icon_bench(p)
			"manual": _icon_manual(p)
			"tablilla": _icon_tablilla(p, false)
			"sello": _icon_sello(p, false)
			"ability": _icon_ability(p, false)
			"boss": _icon_boss(p, false, 0.9)
			"exit": _icon_exit(p, 1.0)
			"player":
				draw_circle(p, 7, Color.WHITE)
		draw_string(font, Vector2(x + 34, y + 3), str(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.75, 0.74, 0.7))
		x += 34.0 + font.get_string_size(str(it[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 26.0
	if not GameState.is_charm_equipped("semantica"):
		var hint := "Con el amuleto Semántica se marcan también las tablillas y los sellos pendientes"
		var bf := UITheme.body_font()
		var w := bf.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(bf, Vector2(size.x * 0.5 - w * 0.5, y + 44), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 0.6, 0.58, 0.8))
