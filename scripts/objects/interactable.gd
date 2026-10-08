class_name Interactable
extends Area2D
## Área de interacción (capa 8). Muestra un aviso cuando el jugador está
## cerca y reenvía `interact()` al nodo padre.

var prompt := "Interactuar"
var prompt_offset := Vector2(0, -150)
var label: Label
var _near := false


func setup(size: Vector2, offset: Vector2, p_prompt: String) -> void:
	collision_layer = 1 << 7
	collision_mask = 1 << 1
	prompt = p_prompt
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	cs.position = offset
	add_child(cs)
	body_entered.connect(func(b): if b is Player: _set_near(true))
	body_exited.connect(func(b): if b is Player: _set_near(false))
	label = Label.new()
	label.text = prompt
	label.add_theme_font_override("font", UITheme.title_font())
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(300, 0)
	label.position = prompt_offset - Vector2(150, 0)
	label.modulate.a = 0.0
	label.z_index = 50
	add_child(label)


func interact(player: Player) -> void:
	if get_parent().has_method("interact"):
		get_parent().interact(player)


func can_interact() -> bool:
	return not get_parent().has_method("can_interact") or get_parent().can_interact()


func set_prompt(text: String) -> void:
	prompt = text
	if label:
		label.text = "▲ " + text


func _set_near(near: bool) -> void:
	_near = near
	if label == null:
		return
	label.text = "▲ " + prompt
	var tw := label.create_tween()
	tw.tween_property(label, "modulate:a", 1.0 if near and can_interact() else 0.0, 0.2)
