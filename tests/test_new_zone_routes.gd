extends RefCounted
## Rutas obligatorias de las zonas 1, 2, 8 y 9.
##
## ReachMap dice que existe un camino; aqui se comprueba que ese camino se puede
## hacer DE VERDAD: se recorre salto a salto y cada tramo se ejecuta con la
## fisica del jugador (se coloca al jugador en el origen, con carrerilla si la
## superficie lo permite, y se comprueba donde aterriza).
##
## Verificar cada tramo por separado, en vez de recorrer la sala entera de una
## pasada, evita que un fallo de pilotaje a mitad de camino tape el resto.

var t
var room: RoomBase
var player: Player
var map: ReachMap

const TILE := 64.0


func _setup(room_id: String) -> void:
	GameState.new_game()
	room = load("res://rooms/%s.gd" % room_id).new()
	room.room_id = room_id
	t.add_child(room)
	room.build()
	map = ReachMap.new().load_room(room)
	# Las salas se disenan con margen: el bot sigue la ruta comoda, no la que
	# apura el salto al milimetro.
	map.reach = ReachMap.REACH_COMODA
	player = Player.new()
	t.add_child(player)
	await t.get_tree().process_frame
	for e in t.get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	await _frames(4)


func after_each() -> void:
	for a in ["move_left", "move_right", "jump"]:
		Input.action_release(a)
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _frames(n: int) -> void:
	for i in n:
		await t.get_tree().physics_frame


func _tile() -> Vector2:
	return player.global_position / TILE


func _place(spot: Vector2i) -> void:
	player.place_at(Vector2(float(spot.x) + 0.5, float(spot.y) - 0.25) * TILE)
	await _frames(14)


## Ejecuta un tramo del camino: de `a` a `b`, con carrerilla si cabe.
func _do_move(a: Vector2i, b: Vector2i) -> Vector2:
	var right: bool = b.x >= a.x
	var dir := "move_right" if right else "move_left"
	var step := 1 if right else -1
	# Carrerilla: se empieza hasta 3 tiles antes, si hay suelo.
	var start := a
	for i in 3:
		var prev := Vector2i(start.x - step, start.y)
		if map.stand(prev.x, prev.y):
			start = prev
		else:
			break
	await _place(start)
	var takeoff := float(a.x) + (0.5 if start == a else 0.0)
	var goal_x := float(b.x) + 0.5
	# Si el tramo baja sin hueco, basta con correr y dejarse caer: saltar de mas
	# haria aterrizar en una plataforma superior.
	var hueco := false
	for xi in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
		if not map.stand(xi, a.y):
			hueco = true
			break
	var jumped: bool = b.y >= a.y and not (b.y == a.y and hueco)
	Input.action_press(dir)
	if not jumped and start == a:
		Input.action_press("jump")
		jumped = true
	var jump_frame := -1
	var released := false
	for i in 160:
		await t.get_tree().physics_frame
		var p := _tile()
		# Se salta justo al pasar por la casilla de despegue.
		if not jumped and ((right and p.x >= takeoff) or (not right and p.x <= takeoff)):
			Input.action_press("jump")
			jumped = true
			jump_frame = i
		if jump_frame >= 0 and i == jump_frame + 24:
			Input.action_release("jump")
		# Al llegar a la vertical del destino se suelta la direccion: ya se ha
		# recorrido la distancia y asi se cae encima en vez de pasarse.
		if not released and jumped and ((right and p.x >= goal_x) or (not right and p.x <= goal_x)):
			Input.action_release(dir)
			released = true
		if i > 16 and player.is_on_floor() and absf(p.x - goal_x) <= 1.0 and roundi(p.y) == b.y:
			break
	Input.action_release(dir)
	Input.action_release("jump")
	await _frames(10)
	return _tile()


## Recorre el camino de `from` a la entidad de (to_x, to_y), tramo a tramo.
func _check_route(from: Vector2i, to_x: int, to_y: int, label: String) -> void:
	var goal := map.nearest_stand(to_x, to_y)
	t.ok(goal.y >= 0, "%s: el destino es pisable" % label)
	if goal.y < 0:
		return
	var steps := map.path(from, goal)
	t.ok(steps.size() >= 2, "%s: hay camino desde la puerta" % label)
	if steps.size() < 2:
		return
	var fallos := []
	for i in range(steps.size() - 1):
		var a: Vector2i = steps[i]
		var b: Vector2i = steps[i + 1]
		if a.y == b.y and absi(a.x - b.x) <= 1:
			continue                      # andar por terreno llano
		var landed := await _do_move(a, b)
		var ok: bool = roundi(landed.y) == b.y and absf(landed.x - b.x - 0.5) <= 1.2
		if not ok:
			fallos.append("(%d,%d)->(%d,%d) cayo en (%.1f,%.1f)"
				% [a.x, a.y, b.x, b.y, landed.x, landed.y])
	t.ok(fallos.is_empty(), "%s: todos los saltos salen (%s)" % [label, ", ".join(fallos)])


# --- Zona 1 · Ruinas del Backend ------------------------------------------------------

func test_z1_atrio_cruza_el_foso_y_sube_a_las_cornisas() -> void:
	await _setup("z1_atrio")
	await _check_route(Vector2i(3, 19), 52, 18, "atrio: puerta este")
	await _check_route(Vector2i(3, 19), 10, 9, "atrio: cornisa oeste (L116)")
	await _check_route(Vector2i(3, 19), 48, 8, "atrio: cornisa este (L118)")


func test_z1_catacumbas_ruta_obligatoria() -> void:
	await _setup("z1_catacumbas")
	await _check_route(Vector2i(3, 21), 19, 12, "catacumbas: meseta REST (L120)")
	await _check_route(Vector2i(3, 21), 54, 13, "catacumbas: cornisa de salida (L121)")


# --- Zona 2 · Torres de Arquitectura --------------------------------------------------

func test_z2_torre_base_ruta_obligatoria() -> void:
	await _setup("z2_torre_base")
	await _check_route(Vector2i(3, 19), 10, 11, "torre base: cornisa oeste (L137)")
	await _check_route(Vector2i(3, 19), 46, 10, "torre base: cornisa este (L139)")


# --- Zona 8 · Puerto de Contenedores --------------------------------------------------

func test_z8_muelle_ruta_obligatoria() -> void:
	await _setup("z8_muelle")
	await _check_route(Vector2i(3, 19), 10, 12, "muelle: cornisa oeste (L158)")
	await _check_route(Vector2i(3, 19), 46, 11, "muelle: cornisa este (L160)")


# --- Zona 9 · Laboratorio de Pruebas --------------------------------------------------

func test_z9_santuario_inspector_cruza_el_campo_de_pinchos() -> void:
	await _setup("z9_santuario_inspector")
	await _check_route(Vector2i(3, 19), 52, 18, "santuario inspector: pinchos (L190)")
