extends StaticBody2D
## Compuerta: se abre por un nodo *click*, por un jefe o por script.

const TILE := 64

var room: RoomBase
var def: Dictionary
var h := 3
var open_k := 0.0
var shape_node: CollisionShape2D
var persist := true
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	h = int(def.get("h", 3))
	persist = bool(def.get("persist", true))
	collision_layer = 1
	collision_mask = 0
	shape_node = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE * 0.7, h * TILE)
	shape_node.shape = shape
	shape_node.position = Vector2(0, -h * TILE * 0.5)
	add_child(shape_node)
	if def.has("closed_dialog"):
		var it := Interactable.new()
		add_child(it)
		it.setup(Vector2(TILE * 2.2, 120), Vector2(0, -60), "Examinar")
	if bool(def.get("start_open", false)):
		_apply(1.0)
	if persist and GameState.get_flag(room.flag_key(def.id)):
		_apply(1.0)


func is_open() -> bool:
	return open_k >= 1.0


func can_interact() -> bool:
	return not is_open() and def.has("closed_dialog")


func interact(_p: Player) -> void:
	if RoomRouter.world:
		await RoomRouter.world.ui.dialog_id(def.closed_dialog)


func open(animated := true) -> void:
	if is_open():
		return
	if persist:
		GameState.set_flag(room.flag_key(def.id))
	if animated:
		AudioManager.play_sfx("gate_open")
		Events.camera_shake.emit(6.0, 0.5)
		create_tween().tween_method(_apply, open_k, 1.0, 0.7)
	else:
		_apply(1.0)


func close(animated := true) -> void:
	if animated:
		AudioManager.play_sfx("gate_open", 0.2)
		Events.camera_shake.emit(10.0, 0.4)
		create_tween().tween_method(_apply, open_k, 0.0, 0.25)
	else:
		_apply(0.0)


func _apply(k: float) -> void:
	open_k = k
	shape_node.set_deferred("disabled", k > 0.5)
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var height := h * TILE * (1.0 - open_k)
	var col := Color(0.05, 0.06, 0.07)
	var rim := Color(0.4, 0.45, 0.5)
	# Marco superior fijo.
	draw_rect(Rect2(-40, -h * TILE - 12, 80, 16), col)
	if height < 4.0:
		return
	# Barrotes que suben al abrirse.
	var top := -h * TILE
	for i in 4:
		var x := -24 + i * 16
		draw_line(Vector2(x, top), Vector2(x, top + height), col, 10.0)
		draw_line(Vector2(x - 3, top), Vector2(x - 3, top + height), Color(rim, 0.35), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, top + height), Vector2(x + 6, top + height), Vector2(x, top + height + 12)]), col)
	for k in 3:
		var y := top + height * (0.25 + k * 0.25)
		draw_line(Vector2(-30, y), Vector2(30, y), col, 6.0)
	var glow := Color(2.2, 0.6, 1.8, 0.7 + 0.3 * sin(t * 3.0)) if def.get("style", "") == "arena" else Color(0.5, 1.8, 1.6, 0.4)
	draw_circle(Vector2(0, top + height * 0.5), 6, glow)
