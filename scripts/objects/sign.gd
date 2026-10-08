extends Node2D
## Letrero de madera con texto corto. Con "ancho" (px) el texto se reparte en
## varias líneas; {accion} se sustituye por la tecla configurada.

var room: RoomBase
var def: Dictionary


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def


func _lines(text: String, font: Font, size: int, max_w: float) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in text.split(" "):
		var cand := word if cur == "" else cur + " " + word
		if cur != "" and font.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > max_w:
			out.append(cur)
			cur = word
		else:
			cur = cand
	if cur != "":
		out.append(cur)
	return out


func _draw() -> void:
	var dark := Color(0.08, 0.06, 0.04)
	var text := ContentDB.format_text(str(def.get("text", "")))
	var font := UITheme.title_font()
	var ancho := float(def.get("ancho", 0))
	var size := 22 if ancho <= 0.0 else 17
	var lines := PackedStringArray([text]) if ancho <= 0.0 else _lines(text, font, size, ancho)
	var w := 0.0
	for l in lines:
		w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	w += 30.0
	var line_h := float(size) + 6.0
	var h := 44.0 if lines.size() == 1 else line_h * lines.size() + 18.0
	var top := -96.0 - h
	draw_rect(Rect2(-5, -100, 10, 100), dark)
	draw_rect(Rect2(-w * 0.5, top, w, h), dark)
	draw_rect(Rect2(-w * 0.5, top, w, h), Color(0.5, 0.4, 0.25, 0.6), false, 2.0)
	if lines.size() == 1:
		draw_string(font, Vector2(-w * 0.5 + 15, top + 30), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.95, 0.85, 0.6))
		return
	for i in lines.size():
		var lw := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, Vector2(-lw * 0.5, top + 12 + size + i * line_h), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.95, 0.85, 0.6))


func _ready() -> void:
	queue_redraw()
