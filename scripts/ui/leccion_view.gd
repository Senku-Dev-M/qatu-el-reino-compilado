class_name LeccionView
extends Modal
## Lección por páginas: concepto, sintaxis, resultado, errores y comprobación.

signal lesson_checked(id: String, first_time: bool)

const PAGE_LABELS := {
	"concepto": "Concepto", "sintaxis": "Sintaxis", "resultado": "Resultado",
	"errores": "Errores comunes", "comprueba": "Comprueba lo aprendido",
}

var lesson: Dictionary
var page_index := 0
var answered := false

var header: Label
var title: Label
var level_badge: Label
var dots: Control
var page_title: Label
var scroll: ScrollContainer
var content: VBoxContainer
var footer: Label
var prev_hint: Label
var next_hint: Label


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.82)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 110
	panel.offset_right = -110
	panel.offset_top = 50
	panel.offset_bottom = -40
	var sb := UITheme.panel_style(0.98, Color(0.93, 0.78, 0.45, 0.7))
	sb.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var top := HBoxContainer.new()
	vb.add_child(top)
	header = UITheme.label("", 22, UITheme.DIM, true)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(header)
	level_badge = UITheme.label("", 20, UITheme.CYAN, true)
	top.add_child(level_badge)

	title = UITheme.label("", 50, UITheme.GOLD, true)
	vb.add_child(title)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 16)
	vb.add_child(nav)
	page_title = UITheme.label("", 28, UITheme.TEXT, true)
	page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(page_title)
	dots = Control.new()
	dots.custom_minimum_size = Vector2(220, 30)
	dots.draw.connect(_draw_dots)
	nav.add_child(dots)

	var orn := UITheme.ornament(900)
	orn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(orn)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	vb.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)

	var bottom := HBoxContainer.new()
	vb.add_child(bottom)
	prev_hint = UITheme.label("", 22, UITheme.DIM, true)
	bottom.add_child(prev_hint)
	footer = UITheme.label("", 22, UITheme.DIM)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(footer)
	next_hint = UITheme.label("", 22, UITheme.GOLD, true)
	bottom.add_child(next_hint)


func show_leccion(id: String, is_new := false) -> void:
	lesson = ContentDB.leccion(id)
	if lesson.is_empty():
		lesson = {"id": id, "titulo": "[Lección no encontrada: %s]" % id, "paginas": [{"tipo": "concepto", "titulo": "-", "texto": ""}], "sala": "", "nivel": ""}
	var pos := ContentDB.posicion_en_sala(id)
	header.text = "%s  ·  LECCIÓN %d DE %d%s" % [ContentDB.nombre_sala(str(lesson.get("sala", ""))).to_upper(), pos.x, pos.y, "  ·  NUEVA" if is_new else ""]
	level_badge.text = "NIVEL %s" % str(lesson.get("nivel", "")).to_upper()
	title.text = lesson.titulo
	page_index = 0
	open_modal()
	AudioManager.play_sfx("tablet")
	_show_page()


func _pages() -> Array:
	return lesson.get("paginas", [])


func _show_page() -> void:
	answered = false
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	var pages := _pages()
	var p: Dictionary = pages[page_index]
	var tipo := str(p.get("tipo", "concepto"))
	page_title.text = "%d. %s — %s" % [page_index + 1, PAGE_LABELS.get(tipo, tipo), p.get("titulo", "")]
	dots.queue_redraw()
	scroll.scroll_vertical = 0

	if str(p.get("texto", "")) != "":
		content.add_child(_rich(RichFormat.lesson_text(ContentDB.format_text(p.texto)), 30))

	var has_code := str(p.get("codigo", "")) != ""
	var has_view := p.has("vista")
	if has_code or has_view:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		content.add_child(row)
		if has_code:
			var code_box := _code_panel(str(p.codigo), str(p.get("lenguaje", "html")))
			code_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(code_box)
		if has_view:
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if has_code:
				col.add_child(UITheme.label("El navegador muestra:", 20, UITheme.DIM, true))
			var preview := BrowserPreview.new()
			col.add_child(preview)
			preview.show_vista(p.vista)
			row.add_child(col)

	for er in p.get("errores", []):
		content.add_child(_error_card(er, str(p.get("lenguaje", "html"))))

	if tipo == "comprueba":
		_build_question(p.get("pregunta", {}))

	var last := page_index >= pages.size() - 1
	prev_hint.text = "◀ %s" % Settings.key_name("move_left") if page_index > 0 else ""
	next_hint.text = ("Terminar [%s]" % Settings.key_name("jump")) if last else ("%s ▶" % Settings.key_name("move_right"))
	footer.text = "Página %d de %d   ·   [%s] Cerrar   ·   ↑ ↓ desplazar" % [page_index + 1, pages.size(), Settings.key_name("attack")]


func _rich(bbcode: String, size: int) -> RichTextLabel:
	return RichFormat.text_label(bbcode, size)


func _code_panel(src: String, lang: String, highlight := -1) -> PanelContainer:
	return RichFormat.code_panel(src, lang, highlight)


func _error_card(er: Dictionary, lang: String) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	vb.add_child(hb)
	for side in [["✗ Incorrecto", er.mal, UITheme.RED], ["✓ Correcto", er.bien, Color(0.55, 0.9, 0.55)]]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UITheme.label(side[0], 22, side[2], true))
		col.add_child(_code_panel(str(side[1]), str(er.get("lenguaje", lang))))
		hb.add_child(col)
	vb.add_child(_rich(RichFormat.lesson_text(str(er.explicacion)), 26))
	return vb


func _build_question(q: Dictionary) -> void:
	content.add_child(_rich("[b]%s[/b]" % RichFormat.lesson_text(str(q.get("enunciado", ""))), 32))
	if str(q.get("codigo", "")) != "":
		content.add_child(_code_panel(str(q.codigo), str(q.get("lenguaje", "html"))))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	content.add_child(box)
	var feedback := _rich("", 28)
	var letters := ["A", "B", "C", "D"]
	var opts: Array = q.get("opciones", [])
	for i in opts.size():
		var b := Button.new()
		b.text = "%s)  %s" % [letters[i], opts[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 27)
		b.pressed.connect(func():
			if answered:
				return
			var ok := i == int(q.correcta)
			if ok:
				answered = true
				for other in box.get_children():
					other.disabled = true
				b.add_theme_color_override("font_disabled_color", UITheme.GOLD)
				feedback.text = "[color=#f2c46b][b]¡Correcto![/b][/color]  " + RichFormat.lesson_text(str(q.explicacion))
				AudioManager.play_sfx("sello_ok")
				var first := GameState.complete_lesson(lesson.id)
				lesson_checked.emit(lesson.id, first)
			else:
				b.disabled = true
				b.add_theme_color_override("font_disabled_color", UITheme.RED)
				feedback.text = "[color=#f07a7a][b]No es correcto.[/b][/color] Vuelve a mirar las páginas anteriores (◀) o prueba otra opción."
				AudioManager.play_sfx("sello_bad"))
		b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
		box.add_child(b)
	content.add_child(feedback)
	await get_tree().process_frame
	if box.get_child_count() > 0 and visible:
		(box.get_child(0) as Button).grab_focus()


func _draw_dots() -> void:
	var n := _pages().size()
	for i in n:
		var p := Vector2(dots.size.x - (n - i) * 26 + 8, 15)
		if i == page_index:
			dots.draw_circle(p, 8, UITheme.GOLD)
		else:
			dots.draw_circle(p, 6, Color(0.4, 0.4, 0.4))


func _go(delta: int) -> void:
	var n := _pages().size()
	var next := clampi(page_index + delta, 0, n - 1)
	if next == page_index:
		return
	page_index = next
	AudioManager.play_sfx("ui_move")
	_show_page()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var last := page_index >= _pages().size() - 1
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		get_viewport().set_input_as_handled()
		_go(1)
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		get_viewport().set_input_as_handled()
		_go(-1)
	elif event.is_action_pressed("look_down") and not _question_focused():
		get_viewport().set_input_as_handled()
		scroll.scroll_vertical += 120
	elif event.is_action_pressed("look_up") and not _question_focused():
		get_viewport().set_input_as_handled()
		scroll.scroll_vertical -= 120
	elif cancel_pressed(event) or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		close_modal()
	elif (event.is_action_pressed("jump") or event.is_action_pressed("ui_accept")) and not _question_focused():
		get_viewport().set_input_as_handled()
		if last:
			close_modal()
		else:
			_go(1)


func _question_focused() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f is Button and content.is_ancestor_of(f)
