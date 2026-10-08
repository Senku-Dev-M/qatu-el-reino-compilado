class_name CodeRune
extends Area2D
## Runa del refactor de Callback Hell: una línea de código que se golpea.

signal struck(rune: CodeRune)

var line := ""
var order := 0  # posición asignada al acertar (0 = sin asignar)
var state := "idle"  # idle | correct | wrong
var t := 0.0
var flash := 0.0
var move_to := Vector2.ZERO
var width := 360.0


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false
	width = clampf(UITheme.mono_font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 40.0, 180.0, 640.0)
	var c := RectangleShape2D.new()
	c.size = Vector2(width, 60)
	var cs := CollisionShape2D.new()
	cs.shape = c
	add_child(cs)
	z_index = 15
	t = randf() * 5.0


func take_hit(_hit: Dictionary) -> Dictionary:
	if state == "correct":
		return {"solid": true, "energy": false, "pogo": true}
	flash = 1.0
	struck.emit(self)
	return {"solid": true, "energy": true, "pogo": true}


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 3.0)
	position = position.lerp(move_to, 1.0 - exp(-6.0 * delta))
	queue_redraw()


func _draw() -> void:
	var bob := Vector2(0, sin(t * 2.0) * 4.0)
	var col := Color(0.6, 1.8, 2.2)
	if state == "correct":
		col = Color(0.6, 2.4, 1.2)
	elif state == "wrong":
		col = Color(2.6, 0.4, 0.4)
	col = col.lerp(Color(3, 3, 3), flash)
	var rect := Rect2(bob + Vector2(-width * 0.5, -28), Vector2(width, 56))
	draw_rect(rect, Color(0.02, 0.05, 0.07, 0.95))
	draw_rect(rect, col, false, 3.0)
	var font := UITheme.mono_font()
	var s := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(font, bob + Vector2(-s.x * 0.5, 8), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
	if order > 0:
		draw_circle(rect.position + Vector2(0, 0), 16, Color(0.1, 0.3, 0.15))
		draw_string(font, rect.position + Vector2(-6, 7), str(order), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.8, 2.4, 1.2))
