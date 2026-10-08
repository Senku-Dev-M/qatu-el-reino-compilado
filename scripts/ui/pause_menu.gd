class_name PauseMenu
extends Modal
## Menú de pausa.

signal options_requested
signal skins_requested
signal quit_requested

var first: Button


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.7)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.custom_minimum_size = Vector2(520, 0)
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)
	var t := UITheme.label("Pausa", 64, UITheme.GOLD, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UITheme.ornament(420))
	first = _btn(vb, "Continuar", func(): close_modal())
	_btn(vb, "Vestimentas", func(): skins_requested.emit())
	_btn(vb, "Opciones", func(): options_requested.emit())
	_btn(vb, "Guardar y salir al menú", func(): quit_requested.emit())


func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", UITheme.title_font())
	b.pressed.connect(cb)
	b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
	parent.add_child(b)
	return b


func open() -> void:
	open_modal()
	await get_tree().process_frame
	first.grab_focus()


func _input(event: InputEvent) -> void:
	if visible and cancel_pressed(event):
		get_viewport().set_input_as_handled()
		close_modal()
