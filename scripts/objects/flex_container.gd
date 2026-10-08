extends Node2D
## Contenedor flex del mundo. Sus plataformas se colocan con las mismas
## reglas que CSS (FlexLayout). Con la habilidad Flex el jugador cambia el
## valor de la propiedad y las plataformas se recolocan.
##
## Definición:
##   {"type": "flex", "id": ..., "eje": "row" | "column",
##    "propiedad": "justify-content" | "align-items",
##    "largo": tiles del eje principal, "cruce": tiles del eje transversal,
##    "items": [tamaño en tiles de cada plataforma en el eje principal],
##    "valores": [valores que recorre], "valor": valor inicial, "gap": tiles}
## La celda de la definición es la esquina superior izquierda del contenedor.

const TILE := 64
const THICK := 22.0

var room: RoomBase
var def: Dictionary
var column := false
var property := "justify-content"
var main_len := 0.0
var cross_len := 0.0
var gap := 0.0
var item_tiles: Array = []
var values: Array = []
var value := ""
var platforms: Array[AnimatableBody2D] = []
var targets: Array[Rect2] = []
var tweens: Array[Tween] = []
var area: Area2D
var player_inside := false
var t := 0.0
var flash := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	add_to_group("flex_container")
	column = str(def.get("eje", "row")) == "column"
	property = str(def.get("propiedad", "justify-content"))
	main_len = float(def.get("largo", 8)) * TILE
	cross_len = float(def.get("cruce", 1)) * TILE
	gap = float(def.get("gap", 0)) * TILE
	item_tiles = def.get("items", [2, 2])
	values = def.get("valores", FlexLayout.JUSTIFY if property == "justify-content" else FlexLayout.ALIGN)
	var cell: Vector2i = def.cell
	global_position = Vector2(cell) * TILE
	var saved = GameState.get_flag(room.flag_key(def.id))
	value = str(saved) if saved is String and saved in values else str(def.get("valor", values[0]))
	z_index = 3
	for i in item_tiles.size():
		var body := AnimatableBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.sync_to_physics = true
		var cs := CollisionShape2D.new()
		cs.shape = RectangleShape2D.new()
		cs.one_way_collision = true
		body.add_child(cs)
		add_child(body)
		platforms.append(body)
	area = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 1
	var acs := CollisionShape2D.new()
	var ashape := RectangleShape2D.new()
	var size := Vector2(cross_len, main_len) if column else Vector2(main_len, cross_len)
	ashape.size = size + Vector2(TILE * 6, TILE * 6)
	acs.shape = ashape
	acs.position = size * 0.5
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(func(b): if b is Player: player_inside = true)
	area.body_exited.connect(func(b): if b is Player: player_inside = false)
	_layout(false)


## Rectángulos (locales) de cada plataforma para el valor actual.
func compute_rects(for_value: String) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var sizes := []
	for s in item_tiles:
		sizes.append(float(s) * TILE)
	if property == "justify-content":
		var main_sizes := sizes
		if column:
			main_sizes = []
			for s in sizes:
				main_sizes.append(THICK)
		var offs := FlexLayout.justify(main_len, main_sizes, for_value, gap)
		for i in sizes.size():
			if column:
				out.append(Rect2(Vector2(0, offs[i]), Vector2(cross_len, THICK)))
			else:
				out.append(Rect2(Vector2(offs[i], 0), Vector2(sizes[i], THICK)))
	else:
		# align-items: posiciones fijas en el eje principal, se mueven en el transversal.
		var offs := FlexLayout.justify(main_len, sizes, str(def.get("justify_fijo", "space-evenly")), gap)
		for i in sizes.size():
			var a := FlexLayout.align(cross_len, THICK, for_value)
			out.append(Rect2(Vector2(offs[i], a.x), Vector2(sizes[i], a.y)))
	return out


func _layout(animated: bool) -> void:
	targets = compute_rects(value)
	# Un cambio nuevo cancela la animación anterior para que no la sobrescriba.
	for tw in tweens:
		if tw and tw.is_valid():
			tw.kill()
	tweens.clear()
	for i in platforms.size():
		var body := platforms[i]
		var r := targets[i]
		var shape: RectangleShape2D = body.get_child(0).shape
		var cs: CollisionShape2D = body.get_child(0)
		if animated:
			var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
			tweens.append(tw)
			tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(body, "position", r.get_center(), 0.5)
			if not shape.size.is_equal_approx(r.size):
				# stretch: la plataforma se vuelve un bloque sólido.
				cs.set_deferred("one_way_collision", r.size.y <= THICK + 1.0)
				tw.parallel().tween_property(shape, "size", r.size, 0.5)
		else:
			body.position = r.get_center()
			shape.size = r.size
			cs.one_way_collision = r.size.y <= THICK + 1.0


func set_value(new_value: String, animated := true, persist := true) -> void:
	if not (new_value in values):
		return
	value = new_value
	if persist and bool(def.get("persistente", true)):
		GameState.set_flag(room.flag_key(def.id), value)
	flash = 1.0
	_layout(animated)


func cycle() -> void:
	var i := values.find(value)
	set_value(values[(i + 1) % values.size()])
	AudioManager.play_sfx("node_on", 0.05)
	Events.camera_shake.emit(3.0, 0.2)


func _nearest_active() -> bool:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var mine := _distance_to(player.global_position)
	for other in get_tree().get_nodes_in_group("flex_container"):
		if other != self and other.player_inside and other._distance_to(player.global_position) < mine:
			return false
	return true


func _distance_to(p: Vector2) -> float:
	var size := Vector2(cross_len, main_len) if column else Vector2(main_len, cross_len)
	return Rect2(global_position, size).grow(8).get_center().distance_to(p)


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.0)
	if player_inside and not get_tree().paused and Input.is_action_just_pressed("flex") and _nearest_active():
		if GameState.has_ability("flex"):
			cycle()
		else:
			Events.notify.emit("Este contenedor flex no responde. Necesitas la habilidad Flex.")
			AudioManager.play_sfx("sello_bad")
	queue_redraw()


func _draw() -> void:
	var gold := Color(2.2, 1.5, 0.45)
	var cyan := Color(0.5, 2.0, 2.1)
	var size := Vector2(cross_len, main_len) if column else Vector2(main_len, cross_len)
	var box := Rect2(Vector2.ZERO, size)
	# Marco del contenedor (líneas punteadas) y eje principal.
	var dash := 14.0
	var edges := [[box.position, Vector2(box.end.x, 0)], [Vector2(0, box.end.y), box.end], [box.position, Vector2(0, box.end.y)], [Vector2(box.end.x, 0), box.end]]
	for e in edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var d := 0.0
		var dir := (b - a).normalized()
		var length := a.distance_to(b)
		while d < length:
			draw_line(a + dir * d, a + dir * minf(d + dash, length), Color(gold, 0.35 + 0.4 * flash), 2.0)
			d += dash * 2.0
	var axis_from := Vector2(size.x * 0.5, 0) if column else Vector2(0, size.y + 10)
	var axis_to := Vector2(size.x * 0.5, size.y) if column else Vector2(size.x, size.y + 10)
	if property == "justify-content":
		draw_line(axis_from, axis_to, Color(gold, 0.25), 2.0)
	# Plataformas: losas de arenisca numeradas.
	for i in platforms.size():
		var body := platforms[i]
		var shape: RectangleShape2D = body.get_child(0).shape
		var r := Rect2(body.position - shape.size * 0.5, shape.size)
		draw_rect(r, Color(0.58, 0.36, 0.2))
		draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, maxf(0.0, r.size.y - 6))), Color(0.42, 0.25, 0.14))
		draw_line(r.position, Vector2(r.end.x, r.position.y), Color(gold.r, gold.g, gold.b, 0.95), 4.0)
		draw_rect(r, Color(1.2, 0.8, 0.4, 0.8), false, 2.0)
		var num_font := UITheme.mono_font()
		draw_string(num_font, r.get_center() + Vector2(-5, 7), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.8, 1.3, 0.6, 0.9))
	# Etiqueta CSS.
	var font := UITheme.mono_font()
	var text := "%s: %s;" % [property, value]
	var label_pos := Vector2(0, -18) if not column else Vector2(size.x + 14, 24)
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_rect(Rect2(label_pos + Vector2(-6, -22), Vector2(ts.x + 12, 30)), Color(0, 0, 0, 0.55))
	draw_string(font, label_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, cyan.lerp(Color(3, 3, 3), flash))
	if column:
		draw_string(font, label_pos + Vector2(0, 28), "flex-direction: column;", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(cyan, 0.6))
	if player_inside and _nearest_active():
		var hint := ("[%s] cambiar valor" % Settings.key_name("flex")) if GameState.has_ability("flex") else "(requiere Flex)"
		draw_string(UITheme.title_font(), label_pos + Vector2(0, -30 if not column else 56), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.95, 0.85, 0.85 + 0.15 * sin(t * 4.0)))
