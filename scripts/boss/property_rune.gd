class_name PropertyRune
extends Area2D
## Runa del examen del Guardián del Parcial: representa "propiedad: valor".

signal struck(rune: PropertyRune)

var property := "justify-content"
var value := "center"
var state := "idle"  # idle | correct | wrong
var t := 0.0
var flash := 0.0
var move_to := Vector2.ZERO


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false
	var c := RectangleShape2D.new()
	c.size = Vector2(230, 70)
	var cs := CollisionShape2D.new()
	cs.shape = c
	add_child(cs)
	z_index = 15
	t = randf() * 5.0
	move_to = position


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
	var bob := Vector2(0, sin(t * 2.0) * 5.0)
	var col := Color(2.2, 1.5, 0.5)
	if state == "correct":
		col = Color(0.6, 2.4, 1.2)
	elif state == "wrong":
		col = Color(2.6, 0.4, 0.4)
	col = col.lerp(Color(3, 3, 3), flash)
	var rect := Rect2(bob + Vector2(-115, -32), Vector2(230, 64))
	draw_rect(rect, Color(0.06, 0.04, 0.03, 0.95))
	draw_rect(rect, col, false, 3.0)
	var font := UITheme.mono_font()
	var small := property
	var big := value
	var s1 := font.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var s2 := font.get_string_size(big, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(font, bob + Vector2(-s1.x * 0.5, -8), small, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(col, 0.75))
	draw_string(font, bob + Vector2(-s2.x * 0.5, 20), big, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)
