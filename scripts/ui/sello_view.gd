class_name SelloView
extends Modal
## Sello del Conocimiento: reto práctico sin castigo. Tipos: elegir,
## completar (rellenar ___), encontrar_error (elegir la línea) y ordenar
## (construir el código eligiendo las líneas en orden).
## Devuelve true al cerrar si se superó.

signal reread_requested(leccion_id: String)

var sello: Dictionary
var order: Array = []
var reto_index := 0
var reto: Dictionary
var solved := false
var busy := false
var mistakes := 0

var title: Label
var kind_label: Label
var body: VBoxContainer
var scroll: ScrollContainer
var actions: HBoxContainer
var sigil: Control
var sigil_glow := 0.0

const KIND_NAMES := {
	"elegir": "Elige la respuesta correcta",
	"completar": "Completa el código",
	"encontrar_error": "Encuentra la línea con el error",
	"ordenar": "Ordena el código",
}


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.8)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 170
	panel.offset_right = -170
	panel.offset_top = 50
	panel.offset_bottom = -40
	var sb := UITheme.panel_style(0.98, Color(0.55, 0.9, 0.85, 0.6))
	sb.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	sigil = Control.new()
	sigil.custom_minimum_size = Vector2(110, 90)
	sigil.draw.connect(_draw_sigil)
	top.add_child(sigil)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(titles)
	title = UITheme.label("", 44, UITheme.GOLD, true)
	titles.add_child(title)
	kind_label = UITheme.label("", 26, UITheme.CYAN, true)
	titles.add_child(kind_label)
	vb.add_child(UITheme.ornament(700))
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	vb.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	vb.add_child(actions)


func show_sello(id: String) -> void:
	sello = ContentDB.sello(id)
	solved = false
	sigil_glow = 0.0
	mistakes = 0
	title.text = str(sello.get("nombre", id))
	order = range(sello.get("retos", []).size())
	order.shuffle()
	reto_index = 0
	open_modal()
	_show_reto()


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _show_reto() -> void:
	busy = false
	_clear(body)
	_clear(actions)
	var retos: Array = sello.get("retos", [])
	if retos.is_empty():
		body.add_child(UITheme.label("[Sello sin retos]", 30))
		return
	reto = retos[order[reto_index % order.size()]]
	var tipo := str(reto.get("tipo", "elegir"))
	kind_label.text = KIND_NAMES.get(tipo, tipo)
	body.add_child(RichFormat.text_label("[b]%s[/b]" % RichFormat.lesson_text(str(reto.enunciado)), 32))
	match tipo:
		"elegir": _build_choice(false)
		"completar": _build_choice(true)
		"encontrar_error": _build_find_error()
		"ordenar": _build_order()
	var leave := _action("Salir", func(): close_modal(false))
	leave.focus_mode = Control.FOCUS_ALL


func _action(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	actions.add_child(b)
	return b


func _focus_first(container: Node) -> void:
	await get_tree().process_frame
	for c in container.get_children():
		if c is Button and not c.disabled:
			c.grab_focus()
			return


# --- Elegir / completar -----------------------------------------------------------

func _build_choice(with_blank: bool) -> void:
	var lang := str(reto.get("lenguaje", "html"))
	if str(reto.get("codigo", "")) != "":
		body.add_child(RichFormat.code_panel(str(reto.codigo), lang))
	var opts: Array = reto.get("opciones", [])
	var shuffled := range(opts.size())
	shuffled.shuffle()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	body.add_child(box)
	var letters := ["A", "B", "C", "D"]
	for i in shuffled.size():
		var original: int = shuffled[i]
		var b := Button.new()
		b.text = "%s)  %s" % [letters[i], opts[original]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if with_blank:
			b.add_theme_font_override("font", UITheme.mono_font())
		b.add_theme_font_size_override("font_size", 27)
		b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
		b.pressed.connect(func():
			if busy:
				return
			if original == int(reto.correcta):
				for other in box.get_children():
					other.disabled = true
				b.add_theme_color_override("font_disabled_color", UITheme.GOLD)
				var filled := str(reto.get("codigo", "")).replace("___", str(opts[original]))
				_success(filled if with_blank else "", lang)
			else:
				b.disabled = true
				b.add_theme_color_override("font_disabled_color", UITheme.RED)
				_failure())
		box.add_child(b)
	_focus_first(box)


# --- Encontrar el error -------------------------------------------------------------

func _build_find_error() -> void:
	var lines: Array = reto.get("lineas", [])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	body.add_child(box)
	for i in lines.size():
		var b := Button.new()
		b.text = "%2d   %s" % [i + 1, lines[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UITheme.mono_font())
		b.add_theme_font_size_override("font_size", 24)
		b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
		b.pressed.connect(func():
			if busy:
				return
			if i == int(reto.correcta):
				for other in box.get_children():
					other.disabled = true
				b.add_theme_color_override("font_disabled_color", UITheme.RED)
				var fixed: Array = lines.duplicate()
				fixed[i] = reto.corregida
				body.add_child(UITheme.label("Línea corregida:", 24, UITheme.CYAN, true))
				body.add_child(RichFormat.code_panel("\n".join(fixed), str(reto.get("lenguaje", "html")), i))
				_success("", "")
			else:
				b.disabled = true
				_failure())
		box.add_child(b)
	_focus_first(box)


# --- Ordenar -------------------------------------------------------------------------

func _build_order() -> void:
	var lines: Array = reto.get("lineas", [])
	var lang := str(reto.get("lenguaje", "html"))
	var progress := [0]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	body.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UITheme.label("Tu código:", 24, UITheme.DIM, true))
	var built_holder := VBoxContainer.new()
	left.add_child(built_holder)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	right.add_child(UITheme.label("Elige la siguiente línea:", 24, UITheme.DIM, true))
	var refresh_built := func():
		_clear(built_holder)
		var done: Array = lines.slice(0, progress[0])
		built_holder.add_child(RichFormat.code_panel("\n".join(done) if not done.is_empty() else " ", lang))
	refresh_built.call()
	var shuffled := range(lines.size())
	shuffled.shuffle()
	var buttons := []
	for idx in shuffled:
		var b := Button.new()
		b.text = str(lines[idx])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", UITheme.mono_font())
		b.add_theme_font_size_override("font_size", 23)
		b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
		b.set_meta("line", idx)
		buttons.append(b)
		right.add_child(b)
		b.pressed.connect(func():
			if busy:
				return
			var expected: String = str(lines[progress[0]])
			if str(lines[idx]) == expected:
				progress[0] += 1
				b.disabled = true
				AudioManager.play_sfx("node_on")
				refresh_built.call()
				if progress[0] >= lines.size():
					_success("", lang)
				else:
					_focus_first(right)
			else:
				progress[0] = 0
				for other in buttons:
					other.disabled = false
				refresh_built.call()
				_failure("Esa línea no va en esa posición. El código se reinició: empieza otra vez desde la primera línea.")
				_focus_first(right))
	_focus_first(right)


# --- Resultado ----------------------------------------------------------------------

func _success(filled_code: String, lang: String) -> void:
	busy = true
	solved = true
	AudioManager.play_sfx("sello_ok")
	if filled_code != "":
		body.add_child(UITheme.label("Código completo:", 24, UITheme.CYAN, true))
		body.add_child(RichFormat.code_panel(filled_code, lang))
	body.add_child(RichFormat.text_label("[color=#f2c46b][b]¡Correcto! El sello se rompe.[/b][/color]  " + RichFormat.lesson_text(str(reto.explicacion)), 28))
	if reto.has("vista"):
		body.add_child(UITheme.label("El navegador muestra:", 22, UITheme.DIM, true))
		var preview := BrowserPreview.new()
		preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		preview.custom_minimum_size = Vector2(700, 0)
		body.add_child(preview)
		preview.show_vista(reto.vista)
	create_tween().tween_property(self, "sigil_glow", 1.0, 0.6)
	_clear(actions)
	var done := _action("Continuar", func(): close_modal(true))
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	done.grab_focus()


func _failure(message := "") -> void:
	mistakes += 1
	AudioManager.play_sfx("sello_bad")
	var shake := create_tween()
	var base_x := position.x
	for k in 4:
		shake.tween_property(self, "position:x", base_x + (12 if k % 2 == 0 else -12), 0.04)
	shake.tween_property(self, "position:x", base_x, 0.04)
	var text := message if message != "" else "No es correcto. Puedes intentarlo de nuevo."
	if mistakes >= 1:
		text += "\n[color=#8fe3d6]Pista:[/color] " + RichFormat.lesson_text(str(sello.get("pista", "")))
	var existing := body.get_node_or_null("Feedback")
	if existing:
		body.remove_child(existing)
		existing.queue_free()
	var fb := RichFormat.text_label("[color=#f07a7a]%s[/color]" % text if message == "" else text, 27)
	fb.name = "Feedback"
	body.add_child(fb)
	if actions.get_child_count() <= 1:
		_clear(actions)
		_action("Repasar lecciones", _reread)
		_action("Otro reto", func():
			reto_index += 1
			_show_reto())
		_action("Salir", func(): close_modal(false))


func _reread() -> void:
	for lid in sello.get("lecciones", []):
		reread_requested.emit(lid)


func _process(_delta: float) -> void:
	if visible:
		sigil.queue_redraw()


func _draw_sigil() -> void:
	var c := Vector2(50, 45)
	var t := Time.get_ticks_msec() * 0.001
	var col := UITheme.CYAN.lerp(UITheme.GOLD, sigil_glow)
	sigil.draw_arc(c, 40, 0, TAU, 48, Color(col, 0.8), 3.0, true)
	sigil.draw_arc(c, 30, t, t + TAU * 0.75, 36, Color(col, 0.5), 2.0, true)
	sigil.draw_string(UITheme.mono_font(), c + Vector2(-24, 11), "</>", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if cancel_pressed(event):
		get_viewport().set_input_as_handled()
		close_modal(solved)
