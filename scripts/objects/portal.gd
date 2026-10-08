extends Node2D
## Portal andino de piedra. Activo: viaja a otra sala. Sellado: muestra
## qué semana representa.

var room: RoomBase
var def: Dictionary
var t := 0.0
var active := true
var busy := false
var light: PointLight2D
var restored := false


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	active = def.has("to")
	restored = def.has("restored_flag") and bool(GameState.get_flag(def.restored_flag))
	var it := Interactable.new()
	add_child(it)
	it.setup(Vector2(180, 200), Vector2(0, -100), def.get("prompt", "Entrar") if active else "Examinar")
	it.prompt_offset = Vector2(0, -290)
	light = FX.make_light(Color(0.5, 1.0, 0.95) if active else Color(0.5, 0.45, 0.6), 4.0, 0.9 if active else 0.25)
	light.position = Vector2(0, -130)
	add_child(light)
	refresh()


func refresh() -> void:
	visible = not def.has("requires_flag") or bool(GameState.get_flag(def.requires_flag))


func can_interact() -> bool:
	return visible


func spawn_position() -> Vector2:
	return global_position + Vector2(0, -2)


func interact(_p: Player) -> void:
	if busy or RoomRouter.world == null:
		return
	busy = true
	if active:
		AudioManager.play_sfx("grapple")
		FX.burst(get_parent(), global_position + Vector2(0, -130), Color(0.6, 2.4, 2.2), 40, 500.0, 0.8, 0.4, Vector2.ZERO)
		await RoomRouter.go_to(def.to, def.to_door)
	else:
		var ui: GameUI = RoomRouter.world.ui
		await ui.dialog(["Semana %s · %s" % [def.get("week", "?"), def.get("label", "")]] + ContentDB.dialogo("portal_sellado"))
	busy = false


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var stone := Color(0.07, 0.065, 0.08)
	var edge := Color(0.45, 0.4, 0.34)
	var W := 150.0
	var H := 250.0
	# Marco escalonado (chakana).
	var frame := PackedVector2Array([
		Vector2(-W * 0.5 - 30, 0), Vector2(-W * 0.5 - 30, -H), Vector2(-W * 0.5, -H), Vector2(-W * 0.5, -H - 30),
		Vector2(-W * 0.25, -H - 30), Vector2(-W * 0.25, -H - 60), Vector2(W * 0.25, -H - 60), Vector2(W * 0.25, -H - 30),
		Vector2(W * 0.5, -H - 30), Vector2(W * 0.5, -H), Vector2(W * 0.5 + 30, -H), Vector2(W * 0.5 + 30, 0)])
	draw_colored_polygon(frame, stone)
	var fr := frame.duplicate()
	fr.append(fr[0])
	draw_polyline(fr, Color(edge, 0.5), 2.0)
	# Hueco trapezoidal.
	var hole := PackedVector2Array([Vector2(-W * 0.5, 0), Vector2(W * 0.5, 0), Vector2(W * 0.38, -H + 20), Vector2(-W * 0.38, -H + 20)])
	if active:
		draw_colored_polygon(hole, Color(0.02, 0.08, 0.09))
		for i in 5:
			var k := fmod(t * 0.5 + i / 5.0, 1.0)
			var scale := 1.0 - k
			var pts := PackedVector2Array()
			for p in hole:
				pts.append(Vector2(p.x * scale, (p.y + H * 0.5 - 10) * scale - H * 0.5 + 10))
			pts.append(pts[0])
			draw_polyline(pts, Color(0.5, 2.2, 2.0, 0.5 * (1.0 - k)), 2.0)
		draw_circle(Vector2(0, -H * 0.5), 30 + sin(t * 3.0) * 4.0, Color(0.8, 2.6, 2.4, 0.35))
	else:
		draw_colored_polygon(hole, Color(0.03, 0.03, 0.04))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-W * 0.5, -H * 0.5 + 16), str(def.get("week", "")), HORIZONTAL_ALIGNMENT_CENTER, W, 64, Color(0.55, 0.5, 0.6, 0.7))
		# Cadenas del sello.
		draw_line(Vector2(-W * 0.4, -H + 30), Vector2(W * 0.4, -20), Color(0.2, 0.2, 0.25), 6.0)
		draw_line(Vector2(W * 0.4, -H + 30), Vector2(-W * 0.4, -20), Color(0.2, 0.2, 0.25), 6.0)
	# Glifo de semana en el dintel.
	var glyph_col := Color(2.2, 1.6, 0.6) if (active or restored) else Color(0.4, 0.38, 0.35)
	draw_circle(Vector2(0, -H - 30), 10, glyph_col)
