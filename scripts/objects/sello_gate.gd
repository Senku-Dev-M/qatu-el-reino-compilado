extends StaticBody2D
## Puerta sellada: bloquea el paso hasta responder su Sello del Conocimiento.

const TILE := 64

var room: RoomBase
var def: Dictionary
var h := 4
var open_k := 0.0
var t := 0.0
var busy := false
var shape_node: CollisionShape2D
var interactable: Interactable
var light: PointLight2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	h = int(def.get("h", 4))
	collision_layer = 1
	collision_mask = 0
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE * 0.8, h * TILE)
	shape_node.shape = shape
	shape_node.position = Vector2(0, -h * TILE * 0.5)
	add_child(shape_node)
	interactable = Interactable.new()
	add_child(interactable)
	interactable.setup(Vector2(TILE * 3.2, 140), Vector2(0, -70), "Romper el sello")
	interactable.prompt_offset = Vector2(0, -h * TILE - 40)
	light = FX.make_light(Color(0.5, 1.0, 0.95), 3.0, 0.9)
	light.position = Vector2(0, -h * TILE * 0.55)
	add_child(light)
	if def.id in GameState.data.sellos:
		_set_open(1.0)


func can_interact() -> bool:
	return open_k < 0.5 and not busy


func interact(_p: Player) -> void:
	if busy or open_k >= 1.0 or RoomRouter.world == null:
		return
	busy = true
	var ok: bool = await RoomRouter.world.ui.sello(def.id)
	if ok:
		GameState.resolve_sello(def.id)
		GameState.add_bits(30)
		FX.popup_text(get_parent(), global_position + Vector2(0, -h * TILE - 20), "+30")
		AudioManager.play_sfx("gate_open")
		Events.camera_shake.emit(8.0, 0.8)
		FX.burst(get_parent(), global_position + Vector2(0, -h * TILE * 0.5), Color(0.6, 2.2, 2.0), 40, 520.0, 1.2, 0.5, Vector2(0, 200))
		var tw := create_tween()
		tw.tween_method(_set_open, 0.0, 1.0, 1.1).set_ease(Tween.EASE_IN_OUT)
	busy = false


func _set_open(k: float) -> void:
	open_k = k
	shape_node.set_deferred("disabled", k >= 0.6)
	light.energy = 0.9 * (1.0 - k)
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	if open_k < 1.0:
		queue_redraw()


func _draw() -> void:
	var height := h * TILE * (1.0 - open_k)
	if height <= 2.0:
		# Umbral abierto.
		draw_rect(Rect2(-34, -10, 68, 10), Color(0.07, 0.08, 0.08))
		return
	var stone := Color(0.06, 0.065, 0.07)
	var edge := Color(0.35, 0.65, 0.6)
	draw_rect(Rect2(-30, -height, 60, height), stone)
	draw_rect(Rect2(-30, -height, 60, height), Color(edge, 0.55), false, 3.0)
	# Barrotes con código.
	for i in 3:
		var x := -18 + i * 18
		draw_line(Vector2(x, -height + 10), Vector2(x, -10), Color(0.2, 0.3, 0.3), 5.0)
	# Sigilo.
	var c := Vector2(0, -height * 0.55)
	var pulse := 0.6 + 0.4 * sin(t * 2.5)
	var glow := Color(0.6 * pulse + 0.3, 2.2 * pulse, 2.0 * pulse)
	draw_circle(c, 44, Color(0.02, 0.03, 0.03))
	draw_arc(c, 40, 0, TAU, 40, glow, 3.0, true)
	draw_arc(c, 30, t, t + PI * 1.4, 24, Color(glow, 0.7), 2.0, true)
	draw_polyline(PackedVector2Array([c + Vector2(-8, -12), c + Vector2(-18, 0), c + Vector2(-8, 12)]), glow, 3.0, true)
	draw_polyline(PackedVector2Array([c + Vector2(8, -12), c + Vector2(18, 0), c + Vector2(8, 12)]), glow, 3.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-16, 70), str(def.id), HORIZONTAL_ALIGNMENT_CENTER, 32, 22, Color(glow, 0.8))
