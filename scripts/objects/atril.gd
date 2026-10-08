extends Node2D
## Atril: cambia la página de un paginador.
## Definición: {"type": "atril", "target": id del paginador,
##              "accion": "siguiente" | "anterior" | "pagina", "pagina": n}

var room: RoomBase
var def: Dictionary
var t := 0.0
var it: Interactable


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	it = Interactable.new()
	add_child(it)
	it.setup(Vector2(120, 150), Vector2(0, -75), _prompt())


func _prompt() -> String:
	match str(def.get("accion", "siguiente")):
		"anterior": return "Página anterior"
		"pagina": return "Ir a la página %d" % int(def.get("pagina", 1))
	return "Página siguiente"


func target() -> Node:
	return room.get_entity(str(def.get("target", "")))


func interact(_p: Player) -> void:
	var pg = target()
	if pg == null:
		return
	match str(def.get("accion", "siguiente")):
		"anterior": pg.previous_page()
		"pagina": pg.set_page(int(def.get("pagina", 1)))
		_: pg.next_page()
	Events.notify.emit(pg.query_text())


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var wood := Color(0.5, 0.32, 0.18)
	draw_rect(Rect2(-8, -70, 16, 70), wood)
	draw_rect(Rect2(-8, -70, 16, 70), Color(1.2, 0.8, 0.4, 0.6), false, 1.5)
	draw_circle(Vector2(0, -84), 46, Color(2.0, 1.4, 0.6, 0.06))
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(34, 0), Vector2(20, -10), Vector2(-20, -10)]), wood)
	# Libro abierto inclinado.
	var top := Vector2(0, -84)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-40, 10), top + Vector2(0, 16), top + Vector2(0, -6), top + Vector2(-40, -14)]), Color(0.9, 0.84, 0.7))
	draw_colored_polygon(PackedVector2Array([top + Vector2(40, 10), top + Vector2(0, 16), top + Vector2(0, -6), top + Vector2(40, -14)]), Color(0.95, 0.9, 0.78))
	var pg = target() if room else null
	var font := UITheme.mono_font()
	var label := "?"
	if pg:
		label = str(pg.page)
	match str(def.get("accion", "siguiente")):
		"anterior": label = "◀"
		"siguiente": label = "▶"
		"pagina": label = str(int(def.get("pagina", 1)))
	var glow := Color(2.2, 1.6, 0.7, 0.8 + 0.2 * sin(t * 3.0))
	draw_string(font, top + Vector2(-26, 6), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.3, 0.2, 0.1))
	draw_circle(top + Vector2(18, 0), 6, glow)
