class_name Banner
extends Modal
## Anuncio grande al obtener una habilidad, amuleto u objeto.

var kind: Label
var title: Label
var desc: Label
var lesson: Label
var control_hint: Label
var icon: Control
var _can_close_at := 0


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.78)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.custom_minimum_size = Vector2(1300, 0)
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)
	icon = Control.new()
	icon.custom_minimum_size = Vector2(0, 170)
	icon.draw.connect(_draw_icon)
	vb.add_child(icon)
	kind = UITheme.label("", 26, UITheme.DIM, true)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(kind)
	title = UITheme.label("", 72, UITheme.GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	vb.add_child(UITheme.ornament(700))
	desc = UITheme.label("", 36)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(desc)
	control_hint = UITheme.label("", 34, UITheme.TEXT, true)
	control_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(control_hint)
	lesson = UITheme.label("", 30, UITheme.CYAN)
	lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lesson.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(lesson)


func show_banner(p_kind: String, p_title: String, p_desc: String, p_lesson := "", p_control := "") -> void:
	kind.text = p_kind.to_upper()
	title.text = p_title
	desc.text = ContentDB.format_text(p_desc)
	lesson.text = p_lesson
	lesson.visible = p_lesson != ""
	control_hint.text = p_control
	control_hint.visible = p_control != ""
	_can_close_at = Time.get_ticks_msec() + 900
	open_modal()
	AudioManager.play_sfx("item_get")


func _process(_d: float) -> void:
	if visible:
		icon.queue_redraw()


func _draw_icon() -> void:
	var c := Vector2(icon.size.x * 0.5, 85)
	var t := Time.get_ticks_msec() * 0.001
	for i in 12:
		var a := TAU * i / 12.0 + t * 0.2
		icon.draw_line(c + Vector2(cos(a), sin(a)) * 40, c + Vector2(cos(a), sin(a)) * (80 + 10 * sin(t * 2 + i)), Color(UITheme.GOLD, 0.35), 2.0, true)
	icon.draw_circle(c, 34, Color(0.05, 0.05, 0.05))
	icon.draw_arc(c, 34, 0, TAU, 40, UITheme.GOLD, 3.0, true)
	icon.draw_circle(c, 12, Color(UITheme.CYAN, 0.9))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if (accept_pressed(event) or cancel_pressed(event) or event.is_action_pressed("attack")) and Time.get_ticks_msec() >= _can_close_at:
		get_viewport().set_input_as_handled()
		close_modal()
