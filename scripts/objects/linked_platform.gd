class_name LinkedPlatform
extends AnimatableBody2D
## Plataforma enlazada (zona 2): es la «vista» de un nodo de Data Binding. Sube
## `dy` tiles mientras el nodo está enlazado y vuelve a su sitio si se desenlaza.
##
## Definición: {"type": "linked_platform", "id": "plat1", "w": 3, "dy": -3}

const TILE := 64
const THICK := 20.0

var room: RoomBase
var def: Dictionary
var origin := Vector2.ZERO
var bound := false
var width := 3
var tween: Tween
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	width = int(def.get("w", 3))
	origin = position
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width * TILE, THICK)
	cs.shape = rect
	cs.position = Vector2(0, THICK * 0.5)
	cs.one_way_collision = true
	add_child(cs)


func raised_position() -> Vector2:
	return origin + Vector2(0, float(def.get("dy", -3)) * TILE)


func set_bound(value: bool, animated := true) -> void:
	bound = value
	var goal := raised_position() if bound else origin
	if tween and tween.is_valid():
		tween.kill()
	if animated:
		tween = create_tween()
		tween.tween_property(self, "position", goal, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		position = goal


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var w := width * TILE
	var col := Color(0.5, 1.8, 2.6) if bound else Color(0.5, 0.9, 1.2)
	var r := Rect2(-w * 0.5, 0, w, THICK)
	draw_rect(r, Color(0.05, 0.1, 0.16))
	draw_rect(Rect2(r.position, Vector2(w, 4)), col)
	draw_rect(r, Color(col, 0.6), false, 2.0)
	# Guía punteada hasta la otra posición.
	var other := (origin - raised_position()) if bound else (raised_position() - origin)
	for i in 6:
		var y := other.y * (i + 0.5) / 6.0
		draw_circle(Vector2(0, y), 2.0, Color(col, 0.25 + 0.15 * sin(t * 3.0 + i)))
	var font := UITheme.mono_font()
	draw_string(font, Vector2(-w * 0.5, -6), "v-model" if bound else "vista", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col, 0.8))
