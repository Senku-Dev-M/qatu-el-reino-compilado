class_name BrowserPreview
extends PanelContainer
## Vista previa de "lo que muestra el navegador" para las lecciones y retos.
## Recibe {"pestana": "...", "sin_navegador": false, "bloques": [...]}.

const PAGE_BG := Color(0.96, 0.95, 0.92)
const PAGE_TEXT := Color(0.1, 0.1, 0.12)
const LINK := Color(0.1, 0.33, 0.8)

static var _sans: SystemFont

var body: VBoxContainer


static func sans() -> SystemFont:
	if _sans == null:
		_sans = SystemFont.new()
		_sans.font_names = PackedStringArray(["Segoe UI", "Arial", "Helvetica", "sans-serif"])
	return _sans


func show_vista(vista: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var bare := bool(vista.get("sin_navegador", false))
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.2, 0.21, 0.24) if not bare else Color(0.03, 0.04, 0.06, 0.95)
	frame.set_corner_radius_all(8)
	frame.set_content_margin_all(0)
	frame.border_color = Color(0.35, 0.36, 0.4)
	frame.set_border_width_all(1)
	add_theme_stylebox_override("panel", frame)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)
	if not bare:
		outer.add_child(_chrome(str(vista.get("pestana", "Página"))))
	var page := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = PAGE_BG if not bare else Color(0, 0, 0, 0)
	ps.set_content_margin_all(18)
	ps.corner_radius_bottom_left = 8
	ps.corner_radius_bottom_right = 8
	page.add_theme_stylebox_override("panel", ps)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(page)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	page.add_child(body)
	for b in vista.get("bloques", []):
		if b is Dictionary and b.size() == 1:
			var key: String = b.keys()[0]
			var node := _block(key, b[key])
			if node:
				body.add_child(node)


func _chrome(tab_title: String) -> Control:
	var bar := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.16, 0.17, 0.2)
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.content_margin_left = 12
	bs.content_margin_right = 12
	bs.content_margin_top = 6
	bs.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", bs)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bar.add_child(hb)
	var dots := Control.new()
	dots.custom_minimum_size = Vector2(56, 22)
	dots.draw.connect(func():
		for i in 3:
			dots.draw_circle(Vector2(8 + i * 18, 11), 6, [Color(0.93, 0.36, 0.33), Color(0.95, 0.75, 0.25), Color(0.35, 0.8, 0.4)][i]))
	hb.add_child(dots)
	var tab := PanelContainer.new()
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.26, 0.27, 0.31)
	ts.set_corner_radius_all(5)
	ts.content_margin_left = 14
	ts.content_margin_right = 14
	ts.content_margin_top = 2
	ts.content_margin_bottom = 2
	tab.add_theme_stylebox_override("panel", ts)
	var tl := _label(tab_title, 17, Color(0.9, 0.9, 0.92))
	tl.autowrap_mode = TextServer.AUTOWRAP_OFF
	tab.add_child(tl)
	hb.add_child(tab)
	return bar


## Etiqueta de una sola línea: obligatoria dentro de contenedores SHRINK, donde
## el ajuste automático reduce el ancho mínimo y parte el texto letra a letra.
func _fixed_label(text: String, size: int, color: Color, bold := false) -> Label:
	var l := _label(text, size, color, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var f := FontVariation.new()
	f.base_font = sans()
	if bold:
		f.variation_embolden = 0.9
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	return l


func _block(key: String, value: Variant) -> Control:
	match key:
		"h1": return _label(str(value), 34, PAGE_TEXT, true)
		"h2": return _label(str(value), 27, PAGE_TEXT, true)
		"p": return _label(str(value), 20, PAGE_TEXT)
		"nota":
			var n := _label(str(value), 17, Color(0.45, 0.45, 0.5))
			return n
		"error":
			var e := _label("⚠ " + str(value), 19, Color(0.75, 0.15, 0.15), true)
			return e
		"a":
			var l := _label(str(value), 20, LINK)
			l.draw.connect(func():
				var w := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
				l.draw_line(Vector2(0, l.size.y - 3), Vector2(w, l.size.y - 3), LINK, 1.5))
			return l
		"img", "img_rota": return _image(str(value), key == "img_rota")
		"ul", "ol":
			var box := VBoxContainer.new()
			var items: Array = value if value is Array else [value]
			for i in items.size():
				var bullet := "•" if key == "ul" else "%d." % (i + 1)
				box.add_child(_label("   %s  %s" % [bullet, items[i]], 20, PAGE_TEXT))
			return box
		"boton":
			var pc := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.88, 0.88, 0.9)
			sb.border_color = Color(0.55, 0.55, 0.6)
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(4)
			sb.set_content_margin_all(8)
			pc.add_theme_stylebox_override("panel", sb)
			pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			pc.add_child(_fixed_label(str(value), 19, PAGE_TEXT))
			return pc
		"texto": return _styled_text(value)
		"caja": return _box_model(value)
		"consola": return _console(value)
		"arbol": return _tree(value)
		"esqueleto": return _skeleton(value)
		"panel": return _panel(value)
		"separador":
			var hs := HSeparator.new()
			return hs
		"flex": return _flex(value)
		"grid": return _grid(value)
		"responsive": return _responsive(value)
		"flujo": return _flow(value)
		"campo": return _field(value)
		"fieldset": return _fieldset(value)
		"peticion": return _http(value)
		"secuencia": return _sequence(value)
		"red": return _network(value)
		"tabla": return _table(value)
		"paginacion": return _pagination(value)
	return null


# --- Semana 6: tablas de resultados y controles de paginación ----------------------

## {"columnas": [...], "filas": [[...], ...], "resaltar": índice de columna, "pie": texto}
func _table(v: Dictionary) -> Control:
	var cols: Array = v.get("columnas", [])
	var rows: Array = v.get("filas", [])
	var hl := int(v.get("resaltar", -1))
	var grid := GridContainer.new()
	grid.columns = maxi(1, cols.size())
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	var cell := func(text: String, header: bool, highlight: bool, odd: bool) -> Control:
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.82, 0.8, 0.76) if header else (Color(0.93, 0.9, 0.82) if odd else Color(0.98, 0.97, 0.94))
		if highlight:
			sb.bg_color = sb.bg_color.lerp(Color(1.0, 0.85, 0.45), 0.45)
		sb.border_color = Color(0.7, 0.68, 0.64)
		sb.set_border_width_all(1)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		pc.add_theme_stylebox_override("panel", sb)
		var l := _label(text, 17, PAGE_TEXT, header)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		pc.add_child(l)
		return pc
	for i in cols.size():
		grid.add_child(cell.call(str(cols[i]), true, i == hl, false))
	for r in rows.size():
		var row: Array = rows[r]
		for i in cols.size():
			grid.add_child(cell.call(str(row[i]) if i < row.size() else "", false, i == hl, r % 2 == 1))
	var vb := VBoxContainer.new()
	vb.add_child(grid)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if v.has("pie"):
		vb.add_child(_label(str(v.pie), 15, Color(0.45, 0.45, 0.5)))
	return vb


## {"estilo": "numeros" | "anterior_siguiente" | "cargar_mas", "actual": n, "total": n}
func _pagination(v: Dictionary) -> Control:
	var style := str(v.get("estilo", "numeros"))
	var current := int(v.get("actual", 1))
	var total := int(v.get("total", 5))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var plain := func(text: String) -> Control:
		var pl := _label(text, 17, PAGE_TEXT)
		pl.autowrap_mode = TextServer.AUTOWRAP_OFF
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return pl
	var button := func(text: String, active: bool, disabled: bool) -> Control:
		var pc := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.4, 0.8) if active else Color(0.95, 0.94, 0.9)
		sb.border_color = Color(0.6, 0.6, 0.65)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		pc.add_theme_stylebox_override("panel", sb)
		var col := Color.WHITE if active else (Color(0.65, 0.65, 0.68) if disabled else PAGE_TEXT)
		var l := _label(text, 17, col, active)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		pc.add_child(l)
		return pc
	match style:
		"cargar_mas":
			hb.add_child(button.call("Cargar más productos", false, false))
		"anterior_siguiente":
			hb.add_child(button.call("◀ Anterior", false, current <= 1))
			hb.add_child(plain.call("  Página %d de %d  " % [current, total]))
			hb.add_child(button.call("Siguiente ▶", false, current >= total))
		_:
			hb.add_child(button.call("◀", false, current <= 1))
			var shown := []
			for p in [1, current - 1, current, current + 1, total]:
				if p >= 1 and p <= total and not (p in shown):
					shown.append(p)
			shown.sort()
			var last := 0
			for p in shown:
				if p - last > 1:
					hb.add_child(plain.call("…"))
				hb.add_child(button.call(str(p), p == current, false))
				last = p
			hb.add_child(button.call("▶", false, current >= total))
	return hb


# --- Semana 5: formularios, HTTP y red ------------------------------------------

## Control de formulario: {"etiqueta", "tipo": text|email|password|number|date|
## checkbox|radio|textarea|select|submit, "valor", "placeholder", "opciones", "error"}
func _field(v: Dictionary) -> Control:
	var tipo := str(v.get("tipo", "text"))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	if tipo == "submit":
		var btn := PanelContainer.new()
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.9, 0.9, 0.92)
		bs.border_color = Color(0.5, 0.5, 0.55)
		bs.set_border_width_all(1)
		bs.set_corner_radius_all(3)
		bs.content_margin_left = 14
		bs.content_margin_right = 14
		bs.content_margin_top = 5
		bs.content_margin_bottom = 5
		btn.add_theme_stylebox_override("panel", bs)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.add_child(_fixed_label(str(v.get("valor", "Enviar")), 18, PAGE_TEXT))
		vb.add_child(btn)
		return vb
	if tipo in ["checkbox", "radio"]:
		var hb := HBoxContainer.new()
		for opt in v.get("opciones", [v.get("etiqueta", "Opción")]):
			var mark := Control.new()
			mark.custom_minimum_size = Vector2(22, 26)
			var checked := str(opt) == str(v.get("valor", ""))
			mark.draw.connect(func():
				if tipo == "radio":
					mark.draw_circle(Vector2(10, 13), 8, Color.WHITE)
					mark.draw_arc(Vector2(10, 13), 8, 0, TAU, 20, Color(0.4, 0.4, 0.45), 1.5)
					if checked:
						mark.draw_circle(Vector2(10, 13), 4, Color(0.1, 0.4, 0.9))
				else:
					mark.draw_rect(Rect2(2, 5, 16, 16), Color.WHITE)
					mark.draw_rect(Rect2(2, 5, 16, 16), Color(0.4, 0.4, 0.45), false, 1.5)
					if checked:
						mark.draw_polyline(PackedVector2Array([Vector2(5, 13), Vector2(9, 17), Vector2(16, 8)]), Color(0.1, 0.4, 0.9), 2.5))
			hb.add_child(mark)
			var ol := _label(str(opt) + "    ", 18, PAGE_TEXT)
			ol.autowrap_mode = TextServer.AUTOWRAP_OFF
			hb.add_child(ol)
		vb.add_child(hb)
		return vb
	if v.has("etiqueta"):
		var el := _label(str(v.etiqueta), 17, PAGE_TEXT, true)
		el.autowrap_mode = TextServer.AUTOWRAP_OFF
		vb.add_child(el)
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.border_color = Color(0.8, 0.2, 0.2) if v.has("error") else Color(0.55, 0.55, 0.6)
	sb.set_border_width_all(2 if v.has("error") else 1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	box.add_theme_stylebox_override("panel", sb)
	box.custom_minimum_size = Vector2(320, 64 if tipo == "textarea" else 0)
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var value := str(v.get("valor", ""))
	var shown := value
	var col := PAGE_TEXT
	if value == "":
		shown = str(v.get("placeholder", ""))
		col = Color(0.55, 0.55, 0.6)
	elif tipo == "password":
		shown = "•".repeat(value.length())
	match tipo:
		"select": shown += "   ▾"
		"date": shown = (shown if shown != "" else "dd/mm/aaaa") + "   📅"
		"number": shown += "   ⇅"
	var l := _label(shown, 18, col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(l)
	vb.add_child(box)
	if tipo == "select" and v.get("abierto", false):
		for opt in v.get("opciones", []):
			var op := _label("   " + str(opt), 17, PAGE_TEXT)
			op.autowrap_mode = TextServer.AUTOWRAP_OFF
			vb.add_child(op)
	if v.has("error"):
		var er := _label("⚠ " + str(v.error), 15, Color(0.75, 0.15, 0.15))
		er.custom_minimum_size.x = 320
		vb.add_child(er)
	return vb


## {"legend": "Datos de envío", "campos": [campo, ...]}
func _fieldset(v: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(0.6, 0.6, 0.65)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(14)
	sb.content_margin_top = 22
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pc.add_child(vb)
	for f in v.get("campos", []):
		vb.add_child(_field(f))
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", -14)
	var lg := _label("  " + str(v.get("legend", "")) + "  ", 17, PAGE_TEXT, true)
	lg.autowrap_mode = TextServer.AUTOWRAP_OFF
	lg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lg.z_index = 1
	var lg_bg := PanelContainer.new()
	var lgs := StyleBoxFlat.new()
	lgs.bg_color = PAGE_BG
	lg_bg.add_theme_stylebox_override("panel", lgs)
	lg_bg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lg_bg.add_child(lg)
	var lg_margin := MarginContainer.new()
	lg_margin.add_theme_constant_override("margin_left", 12)
	lg_margin.add_child(lg_bg)
	lg_margin.z_index = 1
	outer.add_child(lg_margin)
	outer.add_child(pc)
	return outer


## Petición y respuesta HTTP: {"metodo", "url", "cabeceras": [], "cuerpo",
## "estado", "respuesta_cabeceras": [], "respuesta"}
func _http(v: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.11, 0.13)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(12)
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	pc.add_child(vb)
	var mono := UITheme.mono_font()
	var add := func(text: String, col: Color) -> void:
		var l := _label(text, 17, col)
		l.add_theme_font_override("font", mono)
		vb.add_child(l)
	if v.has("metodo"):
		add.call("→ %s %s" % [v.metodo, v.get("url", "/")], Color(0.55, 0.8, 1.0))
		for h in v.get("cabeceras", []):
			add.call("   " + str(h), Color(0.7, 0.72, 0.78))
		if str(v.get("cuerpo", "")) != "":
			add.call("", Color.WHITE)
			for line in str(v.cuerpo).split("\n"):
				add.call("   " + line, Color(0.9, 0.85, 0.6))
	if v.has("estado"):
		if v.has("metodo"):
			add.call("", Color.WHITE)
		var ok := str(v.estado).begins_with("2") or str(v.estado).begins_with("3")
		add.call("← " + str(v.estado), Color(0.5, 0.9, 0.55) if ok else Color(1.0, 0.45, 0.45))
		for h in v.get("respuesta_cabeceras", []):
			add.call("   " + str(h), Color(0.7, 0.72, 0.78))
		if str(v.get("respuesta", "")) != "":
			for line in str(v.respuesta).split("\n"):
				add.call("   " + line, Color(0.85, 0.87, 0.9))
	return pc


## Diagrama de secuencia: {"actores": ["Navegador", "Servidor"],
## "pasos": [{"de": 0, "a": 1, "texto": "GET /api"}, ...]}
func _sequence(v: Dictionary) -> Control:
	var actors: Array = v.get("actores", ["Navegador", "Servidor"])
	var steps: Array = v.get("pasos", [])
	var c := Control.new()
	var w := float(v.get("ancho", 560))
	c.custom_minimum_size = Vector2(w, 70 + steps.size() * 40)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var font := sans()
		var gap := w / actors.size()
		var xs := []
		for i in actors.size():
			var x := gap * (i + 0.5)
			xs.append(x)
			var ts := font.get_string_size(str(actors[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
			c.draw_rect(Rect2(x - ts.x * 0.5 - 10, 4, ts.x + 20, 30), Color(0.85, 0.87, 0.92))
			c.draw_rect(Rect2(x - ts.x * 0.5 - 10, 4, ts.x + 20, 30), Color(0.4, 0.42, 0.5), false, 1.5)
			c.draw_string(font, Vector2(x - ts.x * 0.5, 25), str(actors[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, PAGE_TEXT)
			var yy := 36.0
			while yy < c.custom_minimum_size.y:
				c.draw_line(Vector2(x, yy), Vector2(x, yy + 6), Color(0.5, 0.5, 0.55), 1.5)
				yy += 12.0
		for i in steps.size():
			var st: Dictionary = steps[i]
			var y := 62.0 + i * 40.0
			var a: float = xs[int(st.get("de", 0))]
			var b: float = xs[int(st.get("a", 1))]
			var col := Color(0.35, 0.65, 1.0) if b > a else Color(1.0, 0.62, 0.25)
			if st.get("error", false):
				col = Color(1.0, 0.35, 0.35)
			var label := str(st.get("texto", ""))
			if absf(a - b) < 1.0:
				c.draw_string(font, Vector2(a + 10, y + 5), "⟳ " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
				continue
			c.draw_line(Vector2(a, y), Vector2(b, y), col, 2.0, true)
			var dir := signf(b - a)
			c.draw_colored_polygon(PackedVector2Array([Vector2(b, y), Vector2(b - dir * 10, y - 5), Vector2(b - dir * 10, y + 5)]), col)
			var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
			c.draw_string(font, Vector2((a + b) * 0.5 - ts.x * 0.5, y - 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col))
	return c


## Pestaña Network: {"filtro": "Fetch/XHR", "filas": [{"nombre", "metodo",
## "estado", "tipo", "tiempo", "inicio": 0..1, "fin": 0..1}], "detalle": [...]}
func _network(v: Dictionary) -> Control:
	var rows: Array = v.get("filas", [])
	var c := Control.new()
	var w := 640.0
	c.custom_minimum_size = Vector2(w, 70 + rows.size() * 30)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var font := UITheme.mono_font()
		c.draw_rect(Rect2(0, 0, w, c.custom_minimum_size.y), Color(0.13, 0.14, 0.17))
		c.draw_rect(Rect2(0, 0, w, 28), Color(0.2, 0.21, 0.25))
		var filters := ["All", "Fetch/XHR", "Doc", "CSS", "JS", "Img"]
		var fx := 8.0
		for f in filters:
			var active: bool = f == str(v.get("filtro", "All"))
			c.draw_string(font, Vector2(fx, 20), f, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.78, 1.0) if active else Color(0.65, 0.65, 0.68))
			fx += font.get_string_size(f, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 18
		var head := ["Nombre", "Estado", "Tipo", "Tiempo", "Cascada"]
		var cols := [8.0, 190.0, 262.0, 330.0, 410.0]
		for i in head.size():
			c.draw_string(font, Vector2(cols[i], 50), head[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.64))
		c.draw_line(Vector2(0, 58), Vector2(w, 58), Color(0.3, 0.3, 0.34), 1.0)
		for i in rows.size():
			var r: Dictionary = rows[i]
			var y := 80.0 + i * 30.0
			var status := str(r.get("estado", "200"))
			var bad := status.begins_with("4") or status.begins_with("5") or status.contains("CORS") or status == "(failed)"
			var col := Color(1.0, 0.45, 0.45) if bad else Color(0.85, 0.87, 0.9)
			if r.get("seleccionada", false):
				c.draw_rect(Rect2(0, y - 18, w, 26), Color(0.2, 0.3, 0.5, 0.6))
			var name := str(r.get("nombre", ""))
			if r.has("metodo"):
				name = "%s %s" % [r.metodo, name]
			c.draw_string(font, Vector2(cols[0], y), name, HORIZONTAL_ALIGNMENT_LEFT, 178, 14, col)
			c.draw_string(font, Vector2(cols[1], y), status, HORIZONTAL_ALIGNMENT_LEFT, 70, 14, col)
			c.draw_string(font, Vector2(cols[2], y), str(r.get("tipo", "")), HORIZONTAL_ALIGNMENT_LEFT, 66, 14, Color(0.7, 0.7, 0.74))
			c.draw_string(font, Vector2(cols[3], y), str(r.get("tiempo", "")), HORIZONTAL_ALIGNMENT_LEFT, 76, 14, Color(0.7, 0.7, 0.74))
			var bw: float = w - cols[4] - 10.0
			var s0 := float(r.get("inicio", 0.0))
			var s1 := float(r.get("fin", 0.1))
			var wait := float(r.get("espera", 0.6))
			var bar := Rect2(cols[4] + s0 * bw, y - 11, maxf(3.0, (s1 - s0) * bw), 12)
			c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * wait, bar.size.y)), Color(0.35, 0.75, 0.45) if not bad else Color(0.8, 0.35, 0.3))
			c.draw_rect(Rect2(bar.position + Vector2(bar.size.x * wait, 0), Vector2(bar.size.x * (1.0 - wait), bar.size.y)), Color(0.3, 0.55, 0.95) if not bad else Color(0.9, 0.45, 0.4)))
	return c


const ITEM_COLORS := [Color(0.36, 0.62, 0.92), Color(0.95, 0.62, 0.3), Color(0.45, 0.78, 0.5), Color(0.82, 0.45, 0.72), Color(0.95, 0.8, 0.35), Color(0.5, 0.7, 0.75)]


func _item_box(c: Control, rect: Rect2, text: String, index: int) -> void:
	var col: Color = ITEM_COLORS[index % ITEM_COLORS.size()]
	c.draw_rect(rect, col)
	c.draw_rect(rect, col.darkened(0.35), false, 2.0)
	var font := sans()
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	c.draw_string(font, rect.get_center() + Vector2(-ts.x * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.08, 0.08, 0.1))


func _container_frame(c: Control, rect: Rect2, label: String) -> void:
	c.draw_rect(rect, Color(0.88, 0.87, 0.83))
	var dash := 10.0
	for side in [[rect.position, Vector2(rect.end.x, rect.position.y)], [Vector2(rect.position.x, rect.end.y), rect.end], [rect.position, Vector2(rect.position.x, rect.end.y)], [Vector2(rect.end.x, rect.position.y), rect.end]]:
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		var length := a.distance_to(b)
		var dir := (b - a).normalized()
		var d := 0.0
		while d < length:
			c.draw_line(a + dir * d, a + dir * minf(d + dash, length), Color(0.45, 0.45, 0.5), 1.5)
			d += dash * 2.0
	if label != "":
		c.draw_string(sans(), rect.position + Vector2(4, -6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 0.4, 0.45))


func _arrow(c: Control, a: Vector2, b: Vector2, col: Color, label: String) -> void:
	c.draw_line(a, b, col, 3.0, true)
	var dir := (b - a).normalized()
	var side := dir.orthogonal() * 7.0
	c.draw_colored_polygon(PackedVector2Array([b + dir * 4.0, b - dir * 10.0 + side, b - dir * 10.0 - side]), col)
	# Horizontal: etiqueta bajo el centro; vertical: a la derecha del centro (no se solapan).
	var mid := (a + b) / 2.0
	var tw := sans().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var pos := mid + Vector2(-tw / 2.0, 20) if absf(dir.x) > 0.5 else mid + Vector2(10, 5)
	c.draw_string(sans(), pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col.lightened(0.25))


## Contenedor flex calculado con FlexLayout (igual que el navegador).
func _flex(v: Dictionary) -> Control:
	var c := Control.new()
	var w := float(v.get("ancho", 520))
	var h := float(v.get("alto", 140))
	var show_axes := bool(v.get("mostrar_ejes", false))
	c.custom_minimum_size = Vector2(w + (130 if show_axes else 40), h + (66 if show_axes else 26))
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var origin := Vector2(4, 20)
		var box := Rect2(origin, Vector2(w, h))
		_container_frame(c, box, str(v.get("etiqueta", "")))
		var items: Array = v.get("items", [])
		var column := str(v.get("direccion", "row")) == "column"
		var gap := float(v.get("gap", 0))
		var justify_v := str(v.get("justify", "flex-start"))
		var align_v := str(v.get("align", "stretch"))
		var main_len := h if column else w
		var cross_len := w if column else h
		var mains := []
		var crosses := []
		var grows := []
		for it in items:
			mains.append(float(it.get("alto" if column else "ancho", 60)))
			crosses.append(float(it.get("ancho" if column else "alto", 40)))
			grows.append(float(it.get("grow", 0)))
		var lines := [range(items.size())]
		if bool(v.get("wrap", false)) and not column:
			lines = FlexLayout.wrap_lines(main_len, mains, gap)
		var cross_offset := 0.0
		var line_cross := cross_len / lines.size() if bool(v.get("wrap", false)) else cross_len
		for line in lines:
			var sizes := []
			var line_grows := []
			for idx in line:
				sizes.append(mains[idx])
				line_grows.append(grows[idx])
			if line_grows.max() > 0.0:
				sizes = FlexLayout.grow(main_len, sizes, line_grows, gap)
			var offs := FlexLayout.justify(main_len, sizes, justify_v, gap)
			for k in line.size():
				var idx: int = line[k]
				var cross_pos := FlexLayout.align(line_cross, minf(crosses[idx], line_cross), align_v)
				var r := Rect2()
				if column:
					r = Rect2(origin + Vector2(cross_pos.x, offs[k]), Vector2(cross_pos.y, sizes[k]))
				else:
					r = Rect2(origin + Vector2(offs[k], cross_offset + cross_pos.x), Vector2(sizes[k], cross_pos.y))
				_item_box(c, r, str(items[idx].get("texto", str(idx + 1))), idx)
			cross_offset += line_cross
		if show_axes:
			var main_col := Color(0.85, 0.55, 0.05)
			var cross_col := Color(0.1, 0.55, 0.6)
			if column:
				_arrow(c, origin + Vector2(w + 16, 0), origin + Vector2(w + 16, h), main_col, "principal")
				_arrow(c, origin + Vector2(0, h + 14), origin + Vector2(w, h + 14), cross_col, "transversal")
			else:
				_arrow(c, origin + Vector2(0, h + 14), origin + Vector2(w, h + 14), main_col, "eje principal")
				_arrow(c, origin + Vector2(w + 16, 0), origin + Vector2(w + 16, h), cross_col, "transversal"))
	return c


## Rejilla calculada con pistas fr/px, auto-colocación o grid-template-areas.
func _grid(v: Dictionary) -> Control:
	var c := Control.new()
	var w := float(v.get("ancho", 520))
	var row_h := float(v.get("fila_alto", 46))
	var gap := float(v.get("gap", 8))
	var cols := FlexLayout.grid_tracks(v.get("columnas", "repeat(3, 1fr)"), w, gap)
	var areas: Array = v.get("areas", [])
	var items: Array = v.get("items", [])
	var rows := areas.size()
	if rows == 0:
		var cells := 0
		for it in items:
			cells += int(it.get("span", 1)) if it is Dictionary else 1
		rows = int(ceil(float(cells) / maxf(1.0, cols.size())))
	var h := rows * row_h + gap * maxi(0, rows - 1)
	c.custom_minimum_size = Vector2(w + 12, h + 30)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var origin := Vector2(4, 20)
		_container_frame(c, Rect2(origin - Vector2(2, 2), Vector2(w + 4, h + 4)), str(v.get("etiqueta", "")))
		var col_x := []
		var x := 0.0
		for cw in cols:
			col_x.append(x)
			x += float(cw) + gap
		# Líneas de las pistas.
		for i in cols.size():
			c.draw_rect(Rect2(origin + Vector2(col_x[i], 0), Vector2(cols[i], h)), Color(0.8, 0.8, 0.78, 0.4))
		if not areas.is_empty():
			var bounds := {}
			for r in areas.size():
				var row: Array = areas[r]
				for col in row.size():
					var name := str(row[col])
					if name == ".":
						continue
					var cell := Rect2(origin + Vector2(col_x[col], r * (row_h + gap)), Vector2(cols[col], row_h))
					bounds[name] = cell if not bounds.has(name) else (bounds[name] as Rect2).merge(cell)
			var i := 0
			for name in bounds.keys():
				_item_box(c, bounds[name], name, i)
				i += 1
		else:
			var col := 0
			var r := 0
			for i in items.size():
				var it = items[i]
				var span := int(it.get("span", 1)) if it is Dictionary else 1
				var text := str(it.get("texto", i + 1)) if it is Dictionary else str(it)
				if col + span > cols.size():
					col = 0
					r += 1
				var x0: float = col_x[col]
				var x1: float = col_x[col + span - 1] + cols[col + span - 1]
				_item_box(c, Rect2(origin + Vector2(x0, r * (row_h + gap)), Vector2(x1 - x0, row_h)), text, i)
				col += span
				if col >= cols.size():
					col = 0
					r += 1)
	return c


## La misma página en varios anchos de pantalla.
func _responsive(v: Dictionary) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 22)
	var items: Array = v.get("items", ["A", "B", "C"])
	for screen in v.get("anchos", []):
		var col := VBoxContainer.new()
		col.add_child(_label(str(screen.get("etiqueta", "")), 15, Color(0.7, 0.68, 0.62), true))
		var w := float(screen.get("ancho", 200))
		var ncols := int(screen.get("columnas", 1))
		var rows := int(ceil(float(items.size()) / ncols))
		var cell_h := 34.0
		var device := Control.new()
		device.custom_minimum_size = Vector2(w + 16, rows * (cell_h + 6) + 20)
		device.draw.connect(func():
			var frame := Rect2(Vector2.ZERO, device.custom_minimum_size)
			device.draw_rect(frame, Color(0.15, 0.15, 0.18))
			device.draw_rect(frame.grow(-4), Color(0.96, 0.95, 0.92))
			var tracks := FlexLayout.grid_tracks("repeat(%d, 1fr)" % ncols, w - 8, 6)
			for i in items.size():
				var cx := i % ncols
				var cy := i / ncols
				var x := 8.0
				for k in cx:
					x += float(tracks[k]) + 6.0
				_item_box(device, Rect2(Vector2(x + 4, 10 + cy * (cell_h + 6)), Vector2(tracks[cx], cell_h)), str(items[i]), i))
		col.add_child(device)
		hb.add_child(col)
	return hb


## Flujo normal: elementos de bloque ocupan una línea; los en línea se colocan seguidos.
func _flow(v: Dictionary) -> Control:
	var c := Control.new()
	var w := float(v.get("ancho", 520))
	var elements: Array = v.get("elementos", [])
	var font := sans()
	var layout := []
	var x := 0.0
	var y := 0.0
	var line_h := 34.0
	for e in elements:
		var text := str(e.get("texto", ""))
		var is_block := str(e.get("tipo", "block")) == "block"
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 20
		if is_block:
			if x > 0.0:
				y += line_h + 6
				x = 0.0
			layout.append([Rect2(0, y, w, line_h), text])
			y += line_h + 6
		else:
			if x + tw > w:
				y += line_h + 6
				x = 0.0
			layout.append([Rect2(x, y, tw, line_h), text])
			x += tw + 6
	if x > 0.0:
		y += line_h + 6
	c.custom_minimum_size = Vector2(w + 12, y + 24)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var origin := Vector2(4, 16)
		_container_frame(c, Rect2(origin - Vector2(2, 2), Vector2(w + 4, y)), "")
		for i in layout.size():
			var r: Rect2 = layout[i][0]
			_item_box(c, Rect2(origin + r.position, r.size), layout[i][1], 0 if r.size.x >= w else 1))
	return c


func _styled_text(v: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.html(str(v.get("fondo", "#00000000")))
	sb.set_content_margin_all(float(v.get("padding", 4)))
	if v.has("borde"):
		sb.border_color = Color.html(str(v.get("color_borde", "#333333")))
		sb.set_border_width_all(int(v.borde))
	pc.add_theme_stylebox_override("panel", sb)
	var l := _label(str(v.get("valor", "")), int(v.get("tamano", 20)), Color.html(str(v.get("color", "#1a1a1e"))), bool(v.get("negrita", false)))
	match str(v.get("alineacion", "left")):
		"center": l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		"right": l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pc.add_child(l)
	return pc


func _image(alt: String, broken: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(240, 130)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var r := Rect2(Vector2.ZERO, Vector2(240, 130))
		if broken:
			c.draw_rect(r, Color(0.9, 0.9, 0.9))
			c.draw_rect(r, Color(0.6, 0.6, 0.6), false, 1.5)
			var ic := Vector2(16, 14)
			c.draw_rect(Rect2(ic, Vector2(22, 26)), Color(0.55, 0.55, 0.55), false, 2.0)
			c.draw_line(ic + Vector2(22, 0), ic + Vector2(0, 26), Color(0.8, 0.2, 0.2), 2.0)
			c.draw_string(sans(), Vector2(48, 34), alt if alt != "" else "(sin texto alternativo)", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color(0.3, 0.3, 0.3))
		else:
			c.draw_rect(r, Color(0.55, 0.75, 0.9))
			c.draw_circle(Vector2(190, 32), 16, Color(1.0, 0.92, 0.5))
			c.draw_colored_polygon(PackedVector2Array([Vector2(0, 130), Vector2(70, 50), Vector2(130, 130)]), Color(0.3, 0.5, 0.35))
			c.draw_colored_polygon(PackedVector2Array([Vector2(90, 130), Vector2(170, 70), Vector2(240, 130)]), Color(0.22, 0.4, 0.28)))
	return c


func _box_model(v: Dictionary) -> Control:
	var content_text := str(v.get("contenido", "Contenido"))
	var padding := float(v.get("padding", 16))
	var border := float(v.get("borde", 4))
	var margin := float(v.get("margin", 20))
	var show_labels := bool(v.get("etiquetas", true))
	var c := Control.new()
	var content_size := Vector2(float(v.get("ancho", 180)), float(v.get("alto", 50)))
	var total := content_size + Vector2(padding + border + margin, padding + border + margin) * 2.0
	c.custom_minimum_size = total + Vector2(0, 8)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		var font := sans()
		var r := Rect2(Vector2.ZERO, total)
		c.draw_rect(r, Color(0.98, 0.8, 0.55, 0.55))
		var br := r.grow(-margin)
		c.draw_rect(br, Color(0.2, 0.2, 0.22))
		var pr := br.grow(-border)
		c.draw_rect(pr, Color(0.62, 0.85, 0.6))
		var cr := pr.grow(-padding)
		c.draw_rect(cr, Color(0.55, 0.72, 0.95))
		c.draw_string(font, cr.position + Vector2(8, cr.size.y * 0.5 + 7), content_text, HORIZONTAL_ALIGNMENT_LEFT, cr.size.x - 12, 18, PAGE_TEXT)
		if show_labels:
			c.draw_string(font, r.position + Vector2(4, 14), "margin %d" % margin, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.25, 0.05))
			c.draw_string(font, pr.position + Vector2(4, 13), "padding %d" % padding, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.35, 0.1))
			c.draw_string(font, br.position + Vector2(br.size.x - 70, -2), "border %d" % border, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.1, 0.1)))
	return c


func _console(lines: Variant) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.11, 0.13)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(12)
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	pc.add_child(vb)
	for line in (lines if lines is Array else [lines]):
		var s := str(line)
		var col := Color(0.85, 0.87, 0.9)
		if s.begins_with("✖") or s.begins_with("Uncaught"):
			col = Color(1.0, 0.45, 0.45)
		elif s.begins_with(">"):
			col = Color(0.55, 0.75, 1.0)
		elif s.begins_with("⚠"):
			col = Color(1.0, 0.8, 0.35)
		var l := _label(s, 18, col)
		l.add_theme_font_override("font", UITheme.mono_font())
		vb.add_child(l)
	return pc


func _panel(v: Dictionary) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.14, 0.17)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(0)
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	pc.add_child(vb)
	var tabs := HBoxContainer.new()
	var tabs_bg := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.2, 0.21, 0.25)
	tsb.set_content_margin_all(6)
	tabs_bg.add_theme_stylebox_override("panel", tsb)
	tabs_bg.add_child(tabs)
	vb.add_child(tabs_bg)
	for tab_name in v.get("pestanas", ["Elements", "Console", "Sources"]):
		var active: bool = tab_name == v.get("titulo", "")
		var tl := _fixed_label("  %s  " % tab_name, 16, Color(0.55, 0.78, 1.0) if active else Color(0.7, 0.7, 0.72), active)
		tabs.add_child(tl)
	var content := VBoxContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(content)
	vb.add_child(margin)
	for line in v.get("lineas", []):
		var s := str(line)
		var selected := s.begins_with("▶")
		var row := PanelContainer.new()
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color(0.2, 0.3, 0.5, 0.6) if selected else Color(0, 0, 0, 0)
		row.add_theme_stylebox_override("panel", rsb)
		var l := _label(s, 17, Color(0.85, 0.87, 0.9))
		l.add_theme_font_override("font", UITheme.mono_font())
		row.add_child(l)
		content.add_child(row)
	return pc


func _tree(root: Dictionary) -> Control:
	var c := Control.new()
	var leaves := _count_leaves(root)
	var depth := _depth(root)
	# Cada hoja recibe al menos el ancho de la etiqueta más larga: con un ancho
	# fijo, los nombres largos se solapaban y se salían por la izquierda.
	var slot := maxf(110.0, _widest_label(root) + 36.0)
	var w := maxf(360.0, leaves * slot)
	var h := depth * 78.0 + 20.0
	c.custom_minimum_size = Vector2(w, h)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func(): _draw_tree_node(c, root, 0.0, w, 0))
	return c


## Pantalla de carga con esqueletos: {"tarjetas": 3, "lineas": 2}.
func _skeleton(v: Variant) -> Control:
	var d: Dictionary = v if v is Dictionary else {}
	var n := int(d.get("tarjetas", 3))
	var lineas := int(d.get("lineas", 2))
	var c := Control.new()
	var card := Vector2(170, 96 + lineas * 14)
	c.custom_minimum_size = Vector2(n * (card.x + 14), card.y)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.draw.connect(func():
		for i in n:
			var o := Vector2(i * (card.x + 14), 0)
			c.draw_rect(Rect2(o, card), Color(0.86, 0.85, 0.82))
			c.draw_rect(Rect2(o + Vector2(10, 10), Vector2(card.x - 20, 56)), Color(0.76, 0.75, 0.72))
			for l in lineas:
				var bw := (card.x - 20) * (0.9 if l == 0 else 0.55)
				c.draw_rect(Rect2(o + Vector2(10, 76 + l * 16), Vector2(bw, 9)), Color(0.76, 0.75, 0.72)))
	return c


func _widest_label(n: Dictionary) -> float:
	var best := UITheme.mono_font().get_string_size(str(n.get("nombre", "?")), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	for k in n.get("hijos", []):
		best = maxf(best, _widest_label(k))
	return best


func _count_leaves(n: Dictionary) -> int:
	var kids: Array = n.get("hijos", [])
	if kids.is_empty():
		return 1
	var total := 0
	for k in kids:
		total += _count_leaves(k)
	return total


func _depth(n: Dictionary) -> int:
	var best := 0
	for k in n.get("hijos", []):
		best = maxi(best, _depth(k))
	return best + 1


func _draw_tree_node(c: Control, n: Dictionary, x0: float, x1: float, level: int) -> Vector2:
	var center := Vector2((x0 + x1) * 0.5, 30.0 + level * 78.0)
	var kids: Array = n.get("hijos", [])
	var total := float(_count_leaves(n))
	var cursor := x0
	for k in kids:
		var span := (x1 - x0) * _count_leaves(k) / total
		var child_center := Vector2(cursor + span * 0.5, 30.0 + (level + 1) * 78.0)
		c.draw_line(center + Vector2(0, 18), child_center - Vector2(0, 18), Color(0.4, 0.45, 0.5), 2.0, true)
		_draw_tree_node(c, k, cursor, cursor + span, level + 1)
		cursor += span
	var label := str(n.get("nombre", "?"))
	var font := UITheme.mono_font()
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var kind := str(n.get("tipo", "elemento"))
	var bg := Color(0.2, 0.42, 0.62) if kind == "elemento" else Color(0.35, 0.55, 0.3)
	if n.get("resaltado", false):
		bg = Color(0.8, 0.5, 0.15)
	var rect := Rect2(center - Vector2(tw * 0.5 + 12, 16), Vector2(tw + 24, 32))
	c.draw_rect(rect, bg)
	c.draw_string(font, rect.position + Vector2(12, 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1))
	return center
