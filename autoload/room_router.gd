extends Node
## Cambia de sala: fundido, instancia el script de la sala, coloca al
## jugador y ajusta cámara, iluminación y música.

const ROOMS_DIR := "res://rooms/"

var world: Node  # World
var current_room: RoomBase
var transitioning := false


func room_script_path(room_id: String) -> String:
	return ROOMS_DIR + room_id + ".gd"


func room_exists(room_id: String) -> bool:
	return ResourceLoader.exists(room_script_path(room_id))


func instantiate_room(room_id: String) -> RoomBase:
	var script: GDScript = load(room_script_path(room_id))
	var room: RoomBase = script.new()
	room.room_id = room_id
	return room


func go_to(room_id: String, spawn_id: String, fade := true) -> void:
	if transitioning or world == null:
		return
	if not room_exists(room_id):
		push_error("RoomRouter: la sala '%s' no existe" % room_id)
		return
	transitioning = true
	var player: Player = world.player
	var walk_dir := 0.0
	if player:
		walk_dir = player.facing if player.state != Player.State.DEAD else 0.0
		player.lock(true)
	if fade:
		await world.fade_out(0.25)
	if current_room:
		current_room.queue_free()
		await get_tree().process_frame
	current_room = instantiate_room(room_id)
	world.room_holder.add_child(current_room)
	current_room.build()
	var first_visit: bool = not (room_id in GameState.data.rooms_visited)
	GameState.visit_room(room_id)
	var spawn := current_room.get_spawn(spawn_id)
	var node := current_room.get_entity(spawn_id)
	if node and node.has_method("entry_walk_dir"):
		walk_dir = node.entry_walk_dir()
	else:
		walk_dir = 0.0
	player.place_at(spawn, walk_dir)
	world.on_room_loaded(current_room, first_visit)
	player.lock(false)
	if walk_dir != 0.0:
		player.place_at(spawn, walk_dir)
	Events.room_entered.emit(room_id)
	if fade:
		await world.fade_in(0.3)
	transitioning = false


func spawn_at_bench() -> void:
	await go_to(GameState.data.bench_room, GameState.data.bench_id)
