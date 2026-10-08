class_name VestimentasView
extends Modal
## Galería de vestimentas: cartas con el retrato de cada una. La base y la de la
## zona 1 están libres; la de la zona N se desbloquea al vencer al jefe de la
## zona N-1. Elegir una cambia al momento el aspecto del Aprendiz.

const CARD := Vector2(176, 232)
const PORTRAIT_DIR := "res://assets/vestimentas/%s.jpg"

var grid: GridContainer
var cards: Array[Button] = []
var big_portrait: TextureRect
var big_frame: Control
var name_label: Label
var zone_label: Label
var desc_label: Label
var status_label: Label
var foot: Label
var selected_id := ""
var t := 0.0


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.88)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 90
	root.offset_right = -90
	root.offset_top = 40
	root.offset_bottom = -30
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title := UITheme.label("Vestimentas", 60, UITheme.GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	root.add_child(UITheme.ornament(640))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 40)
	root.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(CARD.x * 4 + 60, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)

	# Carta grande de detalle.
	big_frame = Control.new()
	big_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	big_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	big_frame.draw.connect(_draw_big_frame)
	body.add_child(big_frame)
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 44
	inner.offset_right = -44
	inner.offset_top = 40
	inner.offset_bottom = -36
	inner.add_theme_constant_override("separation", 8)
	big_frame.add_child(inner)
	big_portrait = TextureRect.new()
	big_portrait.custom_minimum_size = Vector2(0, 430)
	big_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inner.add_child(big_portrait)
	name_label = UITheme.label("", 40, UITheme.GOLD, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(name_label)
	zone_label = UITheme.label("", 22, UITheme.CYAN, true)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(zone_label)
	desc_label = UITheme.label("", 26, UITheme.TEXT)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(300, 0)
	inner.add_child(desc_label)
	status_label = UITheme.label("", 24, UITheme.DIM, true)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(300, 0)
	inner.add_child(status_label)

	foot = UITheme.label("", 22, UITheme.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(foot)


func open() -> void:
	_build_cards()
	open_modal()
	foot.text = "[%s] Vestir    [%s] Cerrar" % [Settings.key_name("jump"), Settings.key_name("attack")]
	await get_tree().process_frame
	for c in cards:
		if str(c.get_meta("id")) == str(GameState.data.get("vestimenta", "base")):
			c.grab_focus()
			return
	if not cards.is_empty():
		cards[0].grab_focus()


static func portrait(id: String) -> Texture2D:
	var v := ContentDB.vestimenta(id)
	var path := PORTRAIT_DIR % str(v.get("retrato", id))
	return load(path) if ResourceLoader.exists(path) else null


func _build_cards() -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	cards.clear()
	for v: Dictionary in ContentDB.vestimentas_ordenadas():
		var id := str(v.id)
		var b := Button.new()
		b.custom_minimum_size = CARD
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		b.set_meta("id", id)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.05, 0.055, 0.07)
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, bg)
		var pic := TextureRect.new()
		pic.name = "retrato"
		pic.position = Vector2(10, 10)
		pic.size = Vector2(CARD.x - 20, CARD.x - 20)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.texture = portrait(id)
		b.add_child(pic)
		var face := Control.new()
		face.name = "cara"
		face.set_anchors_preset(Control.PRESET_FULL_RECT)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.draw.connect(_draw_card.bind(face, b, id))
		b.add_child(face)
		b.focus_entered.connect(func() -> void:
			AudioManager.play_sfx("ui_move")
			_select(id))
		b.mouse_entered.connect(func() -> void: b.grab_focus())
		b.pressed.connect(func() -> void: _equip(id))
		grid.add_child(b)
		cards.append(b)


func _select(id: String) -> void:
	selected_id = id
	var v := ContentDB.vestimenta(id)
	var unlocked := GameState.is_skin_unlocked(id)
	big_portrait.texture = portrait(id)
	big_portrait.modulate = Color.WHITE if unlocked else Color(0.12, 0.12, 0.14)
	name_label.text = str(v.get("nombre", id)) if unlocked else "???"
	var zona := int(v.get("zona", 0))
	zone_label.text = "Vestimenta inicial" if zona == 0 else "SEMANA %d · %s" % [zona, str(ContentDB.zona(zona).get("nombre", "Qatu Restaurada")).to_upper()]
	desc_label.text = str(v.get("descripcion", "")) if unlocked else "Una vestimenta aún sellada."
	if not unlocked:
		var jefe := str(v.get("requiere_jefe", ""))
		status_label.text = "Se desbloquea al vencer a %s" % str(ContentDB.enemy(jefe).get("nombre", jefe))
		status_label.add_theme_color_override("font_color", UITheme.DIM)
	elif str(GameState.data.get("vestimenta", "base")) == id:
		status_label.text = "✦ Vistiendo ahora"
		status_label.add_theme_color_override("font_color", UITheme.GOLD)
	else:
		status_label.text = "[%s] Vestir" % Settings.key_name("jump")
		status_label.add_theme_color_override("font_color", UITheme.CYAN)
	big_frame.queue_redraw()


func _equip(id: String) -> void:
	if GameState.set_skin(id):
		AudioManager.play_sfx("charm_on")
	else:
		AudioManager.play_sfx("sello_bad")
	_select(id)
	for c in cards:
		c.queue_redraw()
		for f in c.get_children():
			(f as Control).queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	# Todas las cartas: la primera vez que se dibuja una textura recién cargada
	# puede salir en blanco, y la enfocada parpadea.
	for c in cards:
		for f in c.get_children():
			(f as Control).queue_redraw()


func _draw_card(face: Control, b: Button, id: String) -> void:
	var r := Rect2(Vector2.ZERO, CARD)
	var unlocked := GameState.is_skin_unlocked(id)
	var equipped := str(GameState.data.get("vestimenta", "base")) == id
	var gold := UITheme.GOLD
	var pr := Rect2(Vector2(10, 10), Vector2(CARD.x - 20, CARD.x - 20))
	var pic := b.get_node_or_null("retrato") as TextureRect
	if pic:
		pic.modulate = Color.WHITE if unlocked else Color(0.1, 0.1, 0.12)
	if not unlocked:
		var c := pr.get_center()
		face.draw_rect(Rect2(c + Vector2(-16, -4), Vector2(32, 26)), Color(0.5, 0.5, 0.52))
		face.draw_arc(c + Vector2(0, -6), 11, PI, TAU, 12, Color(0.5, 0.5, 0.52), 4.0)
		face.draw_circle(c + Vector2(0, 8), 3.5, Color(0.08, 0.08, 0.1))
	var v := ContentDB.vestimenta(id)
	var font := UITheme.title_font()
	var label := str(v.get("nombre", id)) if unlocked else "???"
	var col := gold if equipped else (UITheme.TEXT if unlocked else UITheme.DIM)
	# Nombre en una o dos líneas, centrado y dentro de la carta.
	face.draw_multiline_string(font, Vector2(8, CARD.x + 12), label, HORIZONTAL_ALIGNMENT_CENTER, CARD.x - 16, 15, 2, col)
	var border := Color(gold, 0.35)
	var width := 2.0
	if b.has_focus():
		border = Color(0.55, 0.95, 0.9, 0.7 + 0.3 * sin(t * 5.0))
		width = 4.0
	elif equipped:
		border = gold
		width = 3.0
	face.draw_rect(r, border, false, width)
	if equipped:
		face.draw_colored_polygon(PackedVector2Array([Vector2(CARD.x - 26, 4), Vector2(CARD.x - 18, 12), Vector2(CARD.x - 26, 20), Vector2(CARD.x - 34, 12)]), gold)


func _draw_big_frame() -> void:
	var r := Rect2(Vector2.ZERO, big_frame.size)
	var gold := UITheme.GOLD
	big_frame.draw_rect(r, Color(0.045, 0.05, 0.065))
	big_frame.draw_rect(r.grow(-6), Color(gold, 0.8), false, 3.0)
	big_frame.draw_rect(r.grow(-16), Color(gold, 0.3), false, 1.0)
	for corner: Vector2 in [Vector2(6, 6), Vector2(r.size.x - 6, 6), Vector2(6, r.size.y - 6), r.size - Vector2(6, 6)]:
		big_frame.draw_colored_polygon(PackedVector2Array([corner + Vector2(0, -14), corner + Vector2(14, 0), corner + Vector2(0, 14), corner + Vector2(-14, 0)]), gold)
	# Grecas andinas en la franja inferior.
	var y := r.size.y - 30.0
	var x := 30.0
	while x < r.size.x - 40:
		big_frame.draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 8, y - 8), Vector2(x + 16, y), Vector2(x + 24, y - 8)]), Color(gold, 0.35), 1.5)
		x += 24.0


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("jump") and selected_id != "":
		get_viewport().set_input_as_handled()
		_equip(selected_id)
	elif cancel_pressed(event) or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		close_modal()
