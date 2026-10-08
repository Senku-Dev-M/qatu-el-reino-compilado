extends StaticBody2D
## Arco lector: barrera que solo se abre mientras el jugador tiene un access
## token vigente con el alcance pedido. Muestra 401 (sin token), 403 (alcance
## insuficiente) o 200 (paso libre).
##
## Definición: {"type": "lector", "scope": "vendedor", "h": altura en tiles}

const TILE := 64

var room: RoomBase
var def: Dictionary
var h := 3
var open_k := 0.0
var shape_node: CollisionShape2D
var t := 0.0
var estado := "401"


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	h = int(def.get("h", 3))
	collision_layer = 1
	collision_mask = 0
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE * 0.7, h * TILE)
	shape_node.shape = shape
	shape_node.position = Vector2(0, -h * TILE * 0.5)
	add_child(shape_node)


func scope() -> String:
	return str(def.get("scope", "lector"))


func is_open() -> bool:
	return open_k >= 0.999


## Estado HTTP que muestra el arco según el token del jugador.
func status_for(p: Node) -> String:
	if p == null or not (p is Player):
		return "401"
	var player := p as Player
	if not player.token_valid():
		return "401"
	return "200" if player.token_valid(scope()) else "403"


func _process(delta: float) -> void:
	t += delta
	var p := get_tree().get_first_node_in_group("player")
	estado = status_for(p)
	var target := 1.0 if estado == "200" else 0.0
	open_k = move_toward(open_k, target, delta * 3.0)
	shape_node.set_deferred("disabled", open_k > 0.5)
	queue_redraw()


func _draw() -> void:
	var col := Color(0.6, 2.2, 1.4) if estado == "200" else (Color(2.4, 1.2, 0.4) if estado == "403" else Color(2.4, 0.6, 0.5))
	var stone := Color(0.12, 0.11, 0.18)
	var top := -h * TILE
	# Jambas del arco.
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * 34 - 12, top, 24, h * TILE), stone)
		draw_rect(Rect2(side * 34 - 12, top, 24, h * TILE), Color(col, 0.35), false, 2.0)
	draw_rect(Rect2(-46, top - 18, 92, 20), stone)
	# Cortina de luz: baja al abrirse.
	var height := (h * TILE) * (1.0 - open_k)
	if height > 3.0:
		for i in 6:
			var y := top + height * i / 6.0 + fmod(t * 40.0, height / 6.0)
			draw_line(Vector2(-30, y), Vector2(30, y), Color(col, 0.35), 2.0)
		draw_rect(Rect2(-30, top, 60, height), Color(col, 0.12))
	# Lector y estado.
	var font := UITheme.mono_font()
	var text := "%s · scope: %s" % [estado, scope()]
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	draw_rect(Rect2(Vector2(-ts.x * 0.5 - 8, top - 48), Vector2(ts.x + 16, 26)), Color(0, 0, 0, 0.6))
	draw_string(font, Vector2(-ts.x * 0.5, top - 30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
	draw_circle(Vector2(0, top - 8), 6, Color(col, 0.6 + 0.4 * sin(t * 4.0)))
