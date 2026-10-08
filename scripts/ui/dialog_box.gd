class_name DialogBox
extends Modal
## Cuadro de diálogo inferior con efecto de escritura.

var panel: PanelContainer
var speaker: Label
var text: Label
var arrow: Label
var lines: Array = []
var index := 0
var _typing := 0.0
var _chars := 0


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.25)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(1240, 250)
	panel.offset_left = -620
	panel.offset_right = 620
	panel.offset_bottom = -50
	panel.offset_top = -300
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	speaker = UITheme.label("", 30, UITheme.GOLD, true)
	vb.add_child(speaker)
	text = UITheme.label("", 34)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(1180, 120)
	text.add_theme_font_size_override("font_size", 32)
	vb.add_child(text)
	arrow = UITheme.label("▼", 22, UITheme.GOLD)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(arrow)


func show_lines(p_lines: Array, p_speaker: String) -> void:
	lines = p_lines
	index = 0
	speaker.text = p_speaker
	speaker.visible = p_speaker != ""
	open_modal()
	_show_current()


func _show_current() -> void:
	text.text = ContentDB.format_text(str(lines[index]))
	text.visible_characters = 0
	_chars = text.get_total_character_count()
	_typing = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	if text.visible_characters < _chars and text.visible_characters != -1:
		_typing += delta * 55.0
		var n := int(_typing)
		if n > text.visible_characters and n % 3 == 0:
			AudioManager.play_sfx("type", 0.15)
		text.visible_characters = mini(n, _chars)
	arrow.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006) if _done() else 0.0


func _done() -> bool:
	return text.visible_characters == -1 or text.visible_characters >= _chars


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if accept_pressed(event) or event.is_action_pressed("attack") or event.is_action_pressed("look_up"):
		get_viewport().set_input_as_handled()
		if not _done():
			text.visible_characters = -1
			return
		index += 1
		if index >= lines.size():
			close_modal()
		else:
			AudioManager.play_sfx("ui_move")
			_show_current()
