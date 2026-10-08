extends Node2D
## Decoración educativa de fondo: modelo de cajas, etiquetas gigantes,
## panel de consola y el árbol DOM.

var room: RoomBase
var def: Dictionary
var kind := ""
var t := 0.0


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	kind = str(def.get("kind", ""))
	z_index = -20


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		"box_model": _box_model()
		"big_tag": _big_tag()
		"console": _console()
		"dom_tree": _dom_tree()
		"waterfall": _waterfall()
		"feed": _feed()


func _box_model() -> void:
	var layers := [
		["margin", Color(0.9, 0.6, 0.3), Vector2(560, 400)],
		["border", Color(0.95, 0.85, 0.4), Vector2(440, 290)],
		["padding", Color(0.5, 0.9, 0.6), Vector2(360, 210)],
		["content", Color(0.45, 0.7, 1.0), Vector2(230, 100)],
	]
	var center := Vector2(0, -300)
	var font := UITheme.mono_font()
	for i in layers.size():
		var l: Array = layers[i]
		var size: Vector2 = l[2]
		var pulse := 1.0 + sin(t * 1.4 - i * 0.6) * 0.012
		var r := Rect2(center - size * 0.5 * pulse, size * pulse)
		var col: Color = l[1]
		draw_rect(r, Color(col, 0.05))
		draw_rect(r, Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, 0.55), false, 3.0 if l[0] == "border" else 2.0)
		draw_string(font, r.position + Vector2(12, 28), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(col, 0.8))


func _big_tag() -> void:
	var text := str(def.get("text", "<html>"))
	var font := UITheme.mono_font()
	var size := int(def.get("size", 160))
	var glow := Color(0.5, 1.8, 1.7, 0.06 + 0.02 * sin(t * 1.2))
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	draw_string(font, Vector2(-ts.x * 0.5, -420), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, glow)


func _console() -> void:
	var font := UITheme.mono_font()
	var r := Rect2(-340, -520, 680, 300)
	draw_rect(r, Color(0.02, 0.03, 0.08, 0.3))
	draw_rect(r, Color(0.5, 0.8, 1.6, 0.35), false, 2.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 36)), Color(0.1, 0.14, 0.3, 0.5))
	draw_string(font, r.position + Vector2(14, 26), "Elements   Console   Sources   Network", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.7, 0.85, 1.4, 0.8))
	var lines := [
		["> document.querySelector('#qatu')", Color(0.8, 0.9, 1.2)],
		["  <div id=\"qatu\" class=\"reino\">…</div>", Color(0.6, 1.4, 1.0)],
		["✖ Uncaught TypeError: bug is not defined", Color(1.8, 0.5, 0.5)],
		["> console.log('¿Quién anda ahí?')", Color(0.8, 0.9, 1.2)],
		["  ¿Quién anda ahí?", Color(0.9, 0.9, 0.9)],
	]
	var shown := int(fmod(t, 8.0) / 1.2) + 1
	for i in mini(shown, lines.size()):
		draw_string(font, r.position + Vector2(18, 76 + i * 44), lines[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(lines[i][1], 0.5))
	if int(t * 2.0) % 2 == 0:
		draw_rect(Rect2(r.position + Vector2(18, 76 + mini(shown, lines.size()) * 44 - 18), Vector2(12, 22)), Color(0.8, 0.9, 1.2, 0.8))


## Panel de la pestaña Network con su diagrama de cascada animado.
func _waterfall() -> void:
	var font := UITheme.mono_font()
	var r := Rect2(-120, -640, 760, 360)
	draw_rect(r, Color(0.02, 0.04, 0.07, 0.35))
	draw_rect(r, Color(0.5, 1.4, 1.6, 0.35), false, 2.0)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 36)), Color(0.08, 0.16, 0.22, 0.5))
	draw_string(font, r.position + Vector2(14, 26), "Elements   Console   Network   Sources", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.7, 1.4, 1.5, 0.8))
	var rows := [
		["index.html", "GET", "200", 0.0, 0.12],
		["estilos.css", "GET", "200", 0.12, 0.2],
		["app.js", "GET", "200", 0.12, 0.3],
		["api/productos", "GET", "200", 0.34, 0.62],
		["api/carrito", "POST", "201", 0.62, 0.78],
		["logo.png", "GET", "404", 0.2, 0.26],
	]
	var cycle := fmod(t, 7.0) / 5.0
	var chart_x := r.position.x + 330
	var chart_w := r.size.x - 350
	for i in rows.size():
		var row: Array = rows[i]
		var y := r.position.y + 66 + i * 46
		var err: bool = row[2] == "404"
		var col := Color(1.8, 0.5, 0.45, 0.7) if err else Color(0.8, 1.4, 1.5, 0.6)
		draw_string(font, Vector2(r.position.x + 14, y + 6), "%s  %s  %s" % [row[1], row[2], row[0]], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
		var start: float = row[3]
		var end: float = minf(row[4], cycle)
		if end > start:
			var bar := Rect2(chart_x + start * chart_w, y - 8, (end - start) * chart_w, 16)
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * 0.3, bar.size.y)), Color(0.6, 0.7, 0.8, 0.5))
			draw_rect(Rect2(bar.position + Vector2(bar.size.x * 0.3, 0), Vector2(bar.size.x * 0.7, bar.size.y)), Color(2.2, 0.6, 0.5, 0.6) if err else Color(0.5, 1.6, 2.0, 0.6))


## Lista con scroll infinito: las tarjetas suben y, al asomar el centinela,
## se carga otra página.
func _feed() -> void:
	var font := UITheme.mono_font()
	var r := Rect2(-200, -700, 400, 520)
	draw_rect(r, Color(0.06, 0.04, 0.03, 0.35))
	draw_rect(r, Color(1.6, 1.2, 0.6, 0.3), false, 2.0)
	var cycle := fmod(t * 40.0, 90.0)
	var page := int(t * 40.0 / 360.0) + 1
	for i in 7:
		var y := r.position.y + 12 + i * 90 - cycle
		if y < r.position.y or y > r.end.y - 80:
			continue
		var card := Rect2(Vector2(r.position.x + 16, y), Vector2(r.size.x - 32, 72))
		draw_rect(card, Color(0.9, 0.84, 0.7, 0.12))
		draw_rect(Rect2(card.position + Vector2(8, 8), Vector2(56, 56)), Color(0.7, 0.5, 0.3, 0.15))
		draw_string(font, card.position + Vector2(76, 30), "Producto %d" % (i + page * 4), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.4, 1.2, 0.9, 0.35))
	var sentinel_y := r.end.y - 40
	draw_line(Vector2(r.position.x + 16, sentinel_y), Vector2(r.end.x - 16, sentinel_y), Color(2.2, 1.4, 0.5, 0.4 + 0.2 * sin(t * 4.0)), 2.0)
	draw_string(font, Vector2(r.position.x + 16, sentinel_y + 26), "centinela → GET ?page=%d" % (page + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.2, 1.5, 0.6, 0.5))


func _dom_tree() -> void:
	var font := UITheme.mono_font()
	var nodes := {
		"html": Vector2(0, -620), "head": Vector2(-260, -480), "body": Vector2(260, -480),
		"title": Vector2(-260, -340), "header": Vector2(80, -340), "main": Vector2(440, -340),
		"h1": Vector2(80, -200), "p": Vector2(360, -200), "img": Vector2(540, -200)}
	var links := [["html", "head"], ["html", "body"], ["head", "title"], ["body", "header"], ["body", "main"], ["header", "h1"], ["main", "p"], ["main", "img"]]
	for l in links:
		draw_line(nodes[l[0]], nodes[l[1]], Color(0.4, 1.4, 1.3, 0.25), 3.0, true)
	var i := 0
	for key in nodes.keys():
		var p: Vector2 = nodes[key]
		var pulse := 0.5 + 0.5 * sin(t * 2.0 - i * 0.7)
		draw_circle(p, 34, Color(0.02, 0.05, 0.05, 0.8))
		draw_arc(p, 34, 0, TAU, 32, Color(0.5, 1.8 + pulse, 1.7 + pulse, 0.6), 2.5, true)
		var ts := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		draw_string(font, p + Vector2(-ts.x * 0.5, 7), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.8, 1.6, 1.5, 0.9))
		i += 1
