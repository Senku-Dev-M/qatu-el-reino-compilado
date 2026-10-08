class_name OptionsMenu
extends Modal
## Volumen, pantalla completa y remapeo de teclas.

var list: VBoxContainer
var waiting_action := ""
var waiting_button: Button
var first_focus: Control


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.85)
	var panel := UITheme.center_panel(Vector2(1100, 900))
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var t := UITheme.label("Opciones", 50, UITheme.GOLD, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(t)
	list.add_child(UITheme.ornament(460))
	first_focus = _slider_row("Música", Settings.music_volume, func(v):
		Settings.music_volume = v
		Settings.apply()
		Settings.save_settings())
	_slider_row("Efectos", Settings.sfx_volume, func(v):
		Settings.sfx_volume = v
		Settings.apply()
		Settings.save_settings()
		AudioManager.play_sfx("ui_move"))
	var fs := CheckButton.new()
	fs.text = "Pantalla completa"
	fs.button_pressed = Settings.fullscreen
	fs.add_theme_font_size_override("font_size", 30)
	fs.toggled.connect(func(on):
		Settings.fullscreen = on
		Settings.apply()
		Settings.save_settings())
	list.add_child(fs)
	var ct := UITheme.label("Controles (teclado)", 32, UITheme.GOLD, true)
	list.add_child(ct)
	for action in Settings.ACTIONS.keys():
		var row := HBoxContainer.new()
		var l := UITheme.label(Settings.ACTIONS[action].label, 28)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := Button.new()
		b.custom_minimum_size = Vector2(260, 0)
		b.text = Settings.key_name(action)
		b.pressed.connect(func():
			waiting_action = action
			waiting_button = b
			b.text = "Pulsa una tecla...")
		row.add_child(b)
		list.add_child(row)
	var reset := Button.new()
	reset.text = "Restablecer controles"
	reset.pressed.connect(func():
		Settings.reset_keys()
		_refresh_keys())
	list.add_child(reset)
	var back := Button.new()
	back.text = "Volver"
	back.pressed.connect(func(): close_modal())
	list.add_child(back)


func _slider_row(label_text: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	var l := UITheme.label(label_text, 30)
	l.custom_minimum_size = Vector2(260, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(0, 40)
	s.value_changed.connect(on_change)
	row.add_child(s)
	list.add_child(row)
	return s


func _refresh_keys() -> void:
	for row in list.get_children():
		if row is HBoxContainer and row.get_child_count() == 2 and row.get_child(1) is Button:
			var label_text: String = (row.get_child(0) as Label).text
			for action in Settings.ACTIONS.keys():
				if Settings.ACTIONS[action].label == label_text:
					(row.get_child(1) as Button).text = Settings.key_name(action)


func open() -> void:
	open_modal()
	await get_tree().process_frame
	first_focus.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if waiting_action != "" and event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		if event.physical_keycode != KEY_ESCAPE:
			Settings.set_key(waiting_action, event.physical_keycode)
		waiting_action = ""
		_refresh_keys()
		return
	if cancel_pressed(event):
		get_viewport().set_input_as_handled()
		close_modal()
