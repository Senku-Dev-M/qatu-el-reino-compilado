extends Node2D
## Personajes: La Mentora (hub) y La Depuradora (Cueva DevTools).

var room: RoomBase
var def: Dictionary
var who := "mentora"
var t := 0.0
var talking := false
var facing := -1.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	who = str(def.get("who", "mentora"))
	var it := Interactable.new()
	add_child(it)
	it.setup(Vector2(180, 160), Vector2(0, -80), {"estatua": "Consultar el Códice", "manual": "Consultar al Manual"}.get(who, "Hablar"))
	it.prompt_offset = Vector2(0, -200)
	var l := FX.make_light(Color(1.0, 0.85, 0.6) if who == "mentora" else Color(0.6, 0.8, 1.0), 2.4, 0.6)
	l.position = Vector2(0, -90)
	add_child(l)


func interact(_p: Player) -> void:
	if talking or RoomRouter.world == null:
		return
	talking = true
	var ui: GameUI = RoomRouter.world.ui
	var seen_key := "npc:%s:hablado" % who
	match who:
		"mentora":
			if GameState.get_flag("jefe:impostor_implicito") and not GameState.get_flag("npc:mentora:victoria_z7"):
				await ui.dialog_id("mentora_victoria_z7")
				GameState.set_flag("npc:mentora:victoria_z7")
				GameState.set_flag("npc:mentora:victoria")
			elif GameState.get_flag("jefe:scroll_infinito") and not GameState.get_flag("npc:mentora:victoria_z6"):
				await ui.dialog_id("mentora_victoria_z6")
				GameState.set_flag("npc:mentora:victoria_z6")
				GameState.set_flag("npc:mentora:victoria")
			elif GameState.get_flag("jefe:callback_hell") and not GameState.get_flag("npc:mentora:victoria_z5"):
				await ui.dialog_id("mentora_victoria_z5")
				GameState.set_flag("npc:mentora:victoria_z5")
				GameState.set_flag("npc:mentora:victoria")
			elif GameState.get_flag("jefe:guardian_parcial") and not GameState.get_flag("npc:mentora:victoria_z4"):
				await ui.dialog_id("mentora_victoria_z4")
				GameState.set_flag("npc:mentora:victoria_z4")
				GameState.set_flag("npc:mentora:victoria")
			elif GameState.get_flag("jefe:nodo_huerfano") and not GameState.get_flag("npc:mentora:victoria"):
				await ui.dialog_id("mentora_victoria")
				GameState.set_flag("npc:mentora:victoria")
			elif not GameState.get_flag(seen_key):
				await ui.dialog_id("mentora_inicio")
				GameState.set_flag(seen_key)
			else:
				await ui.dialog_id("mentora_repite")
		"estatua":
			await ui.open_codice()
		"manual":
			await _manual_talk(ui)
		"depuradora":
			if not GameState.get_flag(seen_key):
				await ui.dialog_id("depuradora_inicio")
				GameState.set_flag(seen_key)
			else:
				await ui.dialog_id("depuradora_repite")
			await ui.shop("depuradora")
	talking = false


# --- El Manual -----------------------------------------------------------------------

## Presentación automática (la programa World al entrar por primera vez).
func auto_intro(ui: GameUI) -> void:
	var key := "guia:%s:intro" % room.room_id
	if who != "manual" or GameState.get_flag(key) or talking:
		return
	GameState.set_flag(key)
	talking = true
	await _manual_intro(ui)
	talking = false


func _manual_lines_lessons() -> Array:
	var lines := []
	var list := ContentDB.lecciones_de_sala(room.room_id)
	var text := "Lecciones de esta sala:"
	for i in list.size():
		var l: Dictionary = list[i]
		var mark := "★" if GameState.is_lesson_checked(l.id) else ("✓" if l.id in GameState.data.tablillas else "○")
		text += "\n   %s  %d. %s  (%s)" % [mark, i + 1, l.titulo, l.nivel]
	lines.append(text)
	return lines


func _manual_intro(ui: GameUI) -> void:
	var g := ContentDB.guia(room.room_id)
	var lines: Array = g.get("intro", []).duplicate()
	lines.append_array(_manual_lines_lessons())
	lines.append("Cada tablilla es una lección de varias páginas: usa ◀ ▶ para avanzar y responde la comprobación del final. Si necesitas repasar, háblame o abre el Códice ({codice}).")
	await ui.dialog(lines, "El Manual")


func _manual_talk(ui: GameUI) -> void:
	var g := ContentDB.guia(room.room_id)
	var list := ContentDB.lecciones_de_sala(room.room_id)
	var all_read := true
	for l in list:
		if not (l.id in GameState.data.tablillas):
			all_read = false
	if not GameState.get_flag("guia:%s:intro" % room.room_id):
		GameState.set_flag("guia:%s:intro" % room.room_id)
		await _manual_intro(ui)
	elif all_read and not list.is_empty():
		var lines: Array = g.get("cierre", []).duplicate()
		lines.append_array(_manual_lines_lessons())
		await ui.dialog(lines, "El Manual")
		GameState.set_flag("guia:%s:cierre" % room.room_id)
	else:
		var lines: Array = [str(g.get("recordatorio", "Esto es lo que estudiamos en esta sala."))]
		lines.append_array(_manual_lines_lessons())
		for l in list:
			if not (l.id in GameState.data.tablillas):
				lines.append("Te recomiendo seguir con «%s». Busca su tablilla brillante en esta sala." % l.titulo)
				break
		await ui.dialog(lines, "El Manual")


func _process(delta: float) -> void:
	t += delta
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player and absf(player.global_position.x - global_position.x) > 20.0:
		facing = signf(player.global_position.x - global_position.x)
	queue_redraw()


func _draw() -> void:
	match who:
		"mentora": _draw_mentora()
		"estatua": _draw_estatua()
		"manual": _draw_manual()
		_: _draw_depuradora()


func _draw_manual() -> void:
	# El Manual: libro técnico abierto que flota, con páginas de código.
	var bob := sin(t * 1.8) * 6.0
	var c := Vector2(0, -110 + bob)
	draw_circle(c, 70, Color(0.5, 0.8, 1.6, 0.06))
	draw_line(Vector2(-30, 0), Vector2(30, 0), Color(0.1, 0.12, 0.14), 4.0)
	for i in 3:
		var a := t * 0.9 + TAU * i / 3.0
		draw_circle(c + Vector2(cos(a) * 62, sin(a) * 20 + 30), 2.5, Color(0.8, 1.6, 2.2, 0.8))
	var cover := Color(0.1, 0.16, 0.28)
	var page := Color(0.9, 0.88, 0.8)
	var left := PackedVector2Array([c + Vector2(-62, -30), c + Vector2(-4, -22), c + Vector2(-4, 30), c + Vector2(-62, 24)])
	var right := PackedVector2Array([c + Vector2(62, -30), c + Vector2(4, -22), c + Vector2(4, 30), c + Vector2(62, 24)])
	draw_colored_polygon(PackedVector2Array([c + Vector2(-68, -34), c + Vector2(0, -26), c + Vector2(68, -34), c + Vector2(68, 30), c + Vector2(0, 38), c + Vector2(-68, 30)]), cover)
	draw_colored_polygon(left, page)
	draw_colored_polygon(right, page)
	var ink := Color(0.15, 0.35, 0.55)
	for i in 5:
		var y := -16 + i * 9
		draw_line(c + Vector2(-54, y), c + Vector2(-14 - (i * 7) % 16, y + 2), ink, 2.0)
		draw_line(c + Vector2(12, y + 2), c + Vector2(54 - (i * 5) % 14, y), Color(0.55, 0.3, 0.1) if i % 2 == 0 else ink, 2.0)
	var font := UITheme.mono_font()
	draw_string(font, c + Vector2(-20, -44), "</>", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.7, 1.4, 2.0, 0.8))


func _draw_estatua() -> void:
	# Estatua del Códice: libro abierto de piedra sobre pedestal.
	var stone := Color(0.08, 0.075, 0.085)
	var edge := Color(0.5, 0.45, 0.38)
	draw_rect(Rect2(-50, -30, 100, 30), stone)
	draw_rect(Rect2(-34, -130, 68, 100), stone)
	draw_rect(Rect2(-34, -130, 68, 100), Color(edge, 0.4), false, 2.0)
	var book := Vector2(0, -150)
	draw_colored_polygon(PackedVector2Array([book + Vector2(-70, 10), book + Vector2(0, 22), book + Vector2(0, -26), book + Vector2(-66, -36)]), stone)
	draw_colored_polygon(PackedVector2Array([book + Vector2(70, 10), book + Vector2(0, 22), book + Vector2(0, -26), book + Vector2(66, -36)]), stone)
	var glow := Color(2.2, 1.7, 0.7, 0.6 + 0.3 * sin(t * 1.8))
	for i in 3:
		draw_line(book + Vector2(-56, -20 + i * 11), book + Vector2(-10, -12 + i * 11), glow, 2.0)
		draw_line(book + Vector2(10, -12 + i * 11), book + Vector2(56, -20 + i * 11), glow, 2.0)
	draw_circle(book + Vector2(0, -60), 26 + sin(t * 2.0) * 3.0, Color(1.8, 1.4, 0.6, 0.12))


func _draw_mentora() -> void:
	# Figura alta con poncho tejido, sombrero de ala ancha y bastón.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var breathe := sin(t * 1.6) * 2.0
	var dark := Color(0.06, 0.055, 0.07)
	var poncho := PackedVector2Array([Vector2(-44, -40), Vector2(44, -40), Vector2(30, -130 + breathe), Vector2(-30, -130 + breathe)])
	draw_rect(Rect2(-16, -44, 32, 44), dark)
	draw_colored_polygon(poncho, Color(0.28, 0.1, 0.08))
	for i in 3:
		var y := -118 + i * 26 + breathe * 0.5
		var zz := PackedVector2Array()
		for k in 11:
			zz.append(Vector2(-36 + k * 7.2, y + (0 if k % 2 == 0 else 8)))
		draw_polyline(zz, Color(0.75, 0.55, 0.2), 2.5)
	# Cabeza: máscara ancestral con líneas.
	var head := Vector2(0, -150 + breathe)
	draw_circle(head, 20, Color(0.92, 0.88, 0.8))
	draw_line(head + Vector2(-10, -2), head + Vector2(-4, -2), dark, 3.0)
	draw_line(head + Vector2(4, -2), head + Vector2(10, -2), dark, 3.0)
	draw_line(head + Vector2(0, 6), head + Vector2(0, 12), Color(0.6, 0.3, 0.2), 2.0)
	# Sombrero.
	draw_colored_polygon(PackedVector2Array([head + Vector2(-44, -10), head + Vector2(44, -10), head + Vector2(20, -22), head + Vector2(14, -48), head + Vector2(-14, -48), head + Vector2(-20, -22)]), dark)
	draw_line(head + Vector2(-16, -24), head + Vector2(16, -24), Color(0.75, 0.55, 0.2), 3.0)
	# Bastón con farolillo.
	draw_line(Vector2(54, 0), Vector2(50, -190), Color(0.12, 0.09, 0.06), 6.0)
	var lamp := Vector2(50, -196)
	draw_circle(lamp, 22, Color(1.8, 1.2, 0.5, 0.15))
	draw_circle(lamp, 7 + sin(t * 7.0), Color(2.6, 1.8, 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_depuradora() -> void:
	# Pequeña figura encorvada con gafas-lupa y mochila de pergaminos.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var bob := sin(t * 2.2) * 2.0
	var cloak := Color(0.08, 0.08, 0.14)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(24, -80 + bob), Vector2(-20, -86 + bob)]), cloak)
	# Mochila con rollos.
	draw_rect(Rect2(-54, -92 + bob, 30, 60), Color(0.2, 0.14, 0.08))
	for i in 3:
		draw_circle(Vector2(-39, -96 + bob - i * 14), 8, Color(0.75, 0.68, 0.5))
	# Cabeza y gafas-lupa brillantes.
	var head := Vector2(8, -104 + bob)
	draw_circle(head, 22, Color(0.12, 0.12, 0.2))
	var glow := Color(0.6, 1.6, 2.6)
	draw_arc(head + Vector2(-8, 0), 9, 0, TAU, 20, glow, 3.0)
	draw_arc(head + Vector2(12, 0), 9, 0, TAU, 20, glow, 3.0)
	draw_circle(head + Vector2(-8, 0), 4, Color(glow, 0.8))
	draw_circle(head + Vector2(12, 0), 4, Color(glow, 0.8))
	# Antenas en forma de corchete.
	draw_polyline(PackedVector2Array([head + Vector2(-6, -18), head + Vector2(-14, -34), head + Vector2(-8, -44)]), cloak, 3.0)
	draw_polyline(PackedVector2Array([head + Vector2(10, -18), head + Vector2(18, -34), head + Vector2(12, -44)]), cloak, 3.0)
	# Pluma con la que dibuja el mapa.
	draw_line(Vector2(30, -50 + bob), Vector2(52, -78 + bob), Color(0.9, 0.85, 0.7), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var font := ThemeDB.fallback_font
	if int(t * 1.5) % 4 == 0:
		draw_string(font, Vector2(-30, -150), "console.log()", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 1.4, 2.2, 0.6))
