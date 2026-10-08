extends StaticBody2D
## Plataforma que solo existe mientras su nodo *hover* está activo.

const TILE := 64

var room: RoomBase
var def: Dictionary
var w := 2
var active := false
var fading := false
var shape_node: CollisionShape2D
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	w = int(def.get("w", 2))
	collision_layer = 1
	collision_mask = 0
	position += Vector2((w - 1) * TILE * 0.5, -TILE)
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w * TILE, 22)
	shape_node.shape = shape
	shape_node.position = Vector2(0, 11)
	shape_node.one_way_collision = true
	shape_node.disabled = true
	add_child(shape_node)


func set_active(on: bool, is_fading := false) -> void:
	fading = is_fading
	if on != active:
		active = on
		shape_node.set_deferred("disabled", not on)
		if on:
			FX.burst(get_parent(), global_position + Vector2(0, 10), Color(0.8, 1.4, 2.6), 10, 150.0, 0.4, 0.3, Vector2.ZERO)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var half := w * TILE * 0.5
	var col := Color(0.8, 1.4, 2.6)
	if active:
		var a := 1.0
		if fading:
			a = 0.35 + 0.65 * absf(sin(t * 16.0))
		draw_rect(Rect2(-half, 0, w * TILE, 20), Color(0.05, 0.08, 0.16, a))
		draw_line(Vector2(-half, 0), Vector2(half, 0), Color(col, a), 3.0)
		for i in w * 3:
			var x := -half + 10 + i * (w * TILE - 20) / float(w * 3)
			draw_line(Vector2(x, 20), Vector2(x, 20 + 8 + sin(t * 4.0 + i) * 4.0), Color(col, 0.4 * a), 2.0)
	else:
		var dash := 12.0
		var x := -half
		while x < half:
			draw_line(Vector2(x, 0), Vector2(minf(x + dash, half), 0), Color(col, 0.22), 2.0)
			x += dash * 2.0
		draw_line(Vector2(-half, 0), Vector2(-half, 20), Color(col, 0.22), 2.0)
		draw_line(Vector2(half, 0), Vector2(half, 20), Color(col, 0.22), 2.0)
