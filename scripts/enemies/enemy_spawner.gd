extends Node2D
## Marcador que instancia un bug del tipo indicado al construir la sala.

var room: RoomBase
var def: Dictionary


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def


func on_room_ready(_room: RoomBase) -> void:
	var kind := str(def.get("kind", ""))
	var path := "res://scripts/enemies/%s.gd" % kind
	if not ResourceLoader.exists(path):
		push_error("Enemigo desconocido: %s" % kind)
		return
	var e: EnemyBase = load(path).new()
	e.facing = float(def.get("facing", -1 if randf() < 0.5 else 1))
	e.position = room.entity_layer.to_local(global_position)
	room.entity_layer.add_child(e)
