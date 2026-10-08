extends RefCounted
## Bots que recorren los puzles obligatorios de contenedores flex (zona 4):
## con el valor correcto el tramo es superable y con el inicial no.

var t
var room: RoomBase
var player: Player

const TILE := 64.0


func _setup(room_id: String, start_tile: Vector2, values := {}) -> void:
	GameState.new_game()
	GameState.grant_ability("flex")
	room = load("res://rooms/%s.gd" % room_id).new()
	room.room_id = room_id
	t.add_child(room)
	room.build()
	for id in values:
		var fc = _flex(id)
		t.ok(fc != null, "%s: contenedor %s existe" % [room_id, id])
		if fc != null:
			fc.set_value(values[id], false, false)
	player = Player.new()
	t.add_child(player)
	player.place_at(start_tile * TILE)
	await t.get_tree().process_frame
	for e in t.get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	await _frames(30)


func after_each() -> void:
	for a in ["move_left", "move_right", "jump"]:
		Input.action_release(a)
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _flex(id: String) -> Node:
	for n in t.get_tree().get_nodes_in_group("flex_container"):
		if n.room == room and n.def.id == id:
			return n
	return null


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _tile() -> Vector2:
	return player.global_position / TILE


func _jump_up() -> void:
	Input.action_press("jump")
	await _frames(40)
	Input.action_release("jump")
	await _frames(40)


func _jump_dir(dir: String, frames: int) -> void:
	Input.action_press(dir)
	Input.action_press("jump")
	await _frames(frames)
	Input.action_release(dir)
	await _frames(maxi(1, 40 - frames))
	Input.action_release("jump")
	await _frames(40)


func _walk(dir: String, frames: int) -> void:
	Input.action_press(dir)
	await _frames(frames)
	Input.action_release(dir)
	await _frames(20)


## Corre y salta al llegar al borde de cada plataforma.
func _run_and_hop(dir: String, frames: int) -> void:
	Input.action_press(dir)
	var hold := 0
	var sign := 1.0 if dir == "move_right" else -1.0
	for i in frames:
		await t.get_tree().physics_frame
		if hold > 0:
			hold -= 1
			if hold == 0:
				Input.action_release("jump")
		elif player.is_on_floor() and _edge_ahead(sign):
			Input.action_press("jump")
			hold = 40
	Input.action_release("jump")
	Input.action_release(dir)
	await _frames(40)


func _edge_ahead(sign: float) -> bool:
	var space := player.get_world_2d().direct_space_state
	var from := player.global_position + Vector2(sign * 30.0, -6)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 30), 1)
	return space.intersect_ray(q).is_empty()


func test_desfiladero_bridge_space_evenly() -> void:
	await _setup("z4_desfiladero", Vector2(35.0, 18.9), {"puente": "space-evenly"})
	await _run_and_hop("move_right", 360)
	var p := _tile()
	print("  desfiladero space-evenly: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 52.0 and p.y < 19.2, "cruza el foso (%.1f, %.1f)" % [p.x, p.y])
	t.eq(GameState.data.masks, 5, "sin tocar los pinchos")


func test_desfiladero_bridge_blocked_by_default() -> void:
	await _setup("z4_desfiladero", Vector2(35.0, 18.9))
	t.eq(_flex("puente").value, "flex-start", "valor inicial flex-start")
	await _run_and_hop("move_right", 200)
	var p := _tile()
	print("  desfiladero flex-start: ", p, " máscaras ", GameState.data.masks)
	t.ok(not (p.x > 52.0 and GameState.data.masks == 5), "con flex-start no se cruza sin daño")


func test_caravana_elevator_space_evenly() -> void:
	await _setup("z4_caravana", Vector2(21.5, 22.9), {"elevador": "space-evenly"})
	for i in 3:
		await _jump_up()
	await _jump_dir("move_right", 30)
	await _walk("move_right", 20)
	var p := _tile()
	print("  caravana elevador: ", p)
	t.ok(p.x > 23.0 and p.y < 14.2, "sube a la meseta (%.1f, %.1f)" % [p.x, p.y])


func test_caravana_elevator_blocked_by_default() -> void:
	await _setup("z4_caravana", Vector2(21.5, 22.9))
	for i in 3:
		await _jump_up()
	await _jump_dir("move_right", 30)
	var p := _tile()
	t.ok(p.y > 20.0, "con flex-start no se sube (%.1f, %.1f)" % [p.x, p.y])


func _cross_align_bridge(value: String) -> Vector2:
	await _setup("z4_caravana", Vector2(42.5, 13.9), {"puente_align": value})
	await _run_and_hop("move_right", 220)
	return _tile()


func test_caravana_align_bridge_center() -> void:
	var p := await _cross_align_bridge("center")
	print("  caravana align center: ", p, " máscaras ", GameState.data.masks)
	t.ok(p.x > 55.0 and p.y < 14.2, "cruza con center (%.1f, %.1f)" % [p.x, p.y])


func test_caravana_align_bridge_stretch_blocks() -> void:
	var p := await _cross_align_bridge("stretch")
	t.ok(p.x < 45.0, "stretch bloquea el paso (%.1f)" % p.x)


func test_terrazas_ladder_space_evenly() -> void:
	await _setup("z4_terrazas", Vector2(53.5, 12.9), {"escalera": "space-evenly"})
	for i in 4:
		await _jump_up()
	Input.action_press("jump")
	Input.action_press("move_left")
	await _frames(60)
	Input.action_release("jump")
	await _walk("move_left", 15)
	var p := _tile()
	print("  terrazas escalera: ", p)
	t.ok(p.x < 52.0 and p.y < 4.2, "llega a la cornisa del amuleto (%.1f, %.1f)" % [p.x, p.y])


func test_flex_ability_cycles_value() -> void:
	await _setup("z4_desfiladero", Vector2(40.0, 18.9))
	var fc = _flex("puente")
	var before: String = fc.value
	fc.cycle()
	t.ok(fc.value != before, "cycle cambia el valor")
	t.eq(str(GameState.get_flag(room.flag_key("puente"))), fc.value, "el valor se guarda en la partida")
