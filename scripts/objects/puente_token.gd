extends Node2D
## Puente de tokens: plataformas de luz que existen mientras el jugador tiene
## un access token vigente (con el alcance pedido, si se indica).
##
## Definición: {"type": "puente_token", "scope": "", "items": [[dx, dy, ancho], ...]}

const TILE := 64
const THICK := 20.0

var room: RoomBase
var def: Dictionary
var rects: Array[Rect2] = []
var bodies: Array[StaticBody2D] = []
var active := false
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	z_index = 2
	for item in def.get("items", []):
		var r := Rect2(Vector2(float(item[0]) * TILE - TILE * 0.5, float(item[1]) * TILE), Vector2(float(item[2]) * TILE, THICK))
		rects.append(r)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.get_center()
		cs.one_way_collision = true
		cs.disabled = true
		body.add_child(cs)
		add_child(body)
		bodies.append(body)


func scope() -> String:
	return str(def.get("scope", ""))


func _process(delta: float) -> void:
	t += delta
	var p := get_tree().get_first_node_in_group("player") as Player
	var now := p != null and p.token_valid(scope())
	if now != active:
		active = now
		for b in bodies:
			(b.get_child(0) as CollisionShape2D).set_deferred("disabled", not active)
	queue_redraw()


func _draw() -> void:
	var col := Color(0.8, 2.2, 2.4)
	var font := UITheme.mono_font()
	for r in rects:
		if active:
			draw_rect(r, Color(col, 0.28))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), col)
			for i in int(r.size.x / 26.0):
				var x := r.position.x + 13 + i * 26
				draw_line(Vector2(x, r.position.y + 6), Vector2(x, r.end.y), Color(col, 0.25 + 0.2 * sin(t * 4.0 + i)), 2.0)
		else:
			draw_rect(r, Color(col, 0.12), false, 1.5)
	if not rects.is_empty() and not active:
		var text := "requiere access token" + ("" if scope() == "" else " · scope: %s" % scope())
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_string(font, rects[0].position + Vector2(0, -16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.4, 1.6, 2.2, 0.6))
