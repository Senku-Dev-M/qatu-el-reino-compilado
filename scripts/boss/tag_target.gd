class_name TagTarget
extends Area2D
## Etiqueta flotante de la fase 3. Al golpearla informa al jefe.

signal struck(target: TagTarget)

var tag := "div"
var t := 0.0
var flash := 0.0
var state := "idle"  # idle | correct | wrong
var move_to := Vector2.ZERO


func _ready() -> void:
	collision_layer = 1 << 4
	collision_mask = 0
	monitoring = false
	var c := CircleShape2D.new()
	c.radius = 42
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
	var bob := Vector2(0, sin(t * 2.2) * 6.0)
	var col := Color(0.6, 2.0, 2.2)
	if state == "correct":
		col = Color(2.4, 1.9, 0.7)
	elif state == "wrong":
		col = Color(2.6, 0.4, 0.5)
	col = col.lerp(Color(3, 3, 3), flash)
	draw_circle(bob, 58, Color(col, 0.08))
	var w := 60.0 + tag.length() * 12.0
	var rect := Rect2(bob + Vector2(-w * 0.5, -30), Vector2(w, 60))
	draw_rect(rect, Color(0.02, 0.03, 0.04, 0.95))
	draw_rect(rect, col, false, 3.0)
	var font := UITheme.mono_font()
	var text := "<%s>" % tag
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30)
	draw_string(font, bob + Vector2(-size.x * 0.5, 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)
