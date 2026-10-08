extends Area2D
## Salida lateral de una sala. Al cruzarla se carga la sala destino.

const TILE := 64

var room: RoomBase
var def: Dictionary
var side := 1  # -1 oeste, 1 este
var _armed_at := 0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	collision_layer = 0
	collision_mask = 1 << 1
	var cell: Vector2i = def.cell
	side = -1 if cell.x == 0 else 1
	var h := int(def.get("h", 3))
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE * 0.6, h * TILE)
	cs.shape = shape
	cs.position = Vector2(side * TILE * 0.35, -h * TILE * 0.5)
	add_child(cs)
	body_entered.connect(_on_body)
	_armed_at = Time.get_ticks_msec() + 350


func spawn_position() -> Vector2:
	return global_position + Vector2(-side * TILE * 1.6, -2)


func entry_walk_dir() -> float:
	return -side


func _on_body(body: Node) -> void:
	if not body is Player or Time.get_ticks_msec() < _armed_at:
		return
	if RoomRouter.transitioning or body.state == Player.State.DEAD:
		return
	AudioManager.play_sfx("door", 0.1)
	RoomRouter.go_to(def.to, def.to_door)
