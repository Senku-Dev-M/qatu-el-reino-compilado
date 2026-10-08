extends "res://scripts/objects/gate.gd"
## Compuerta Promise.all: se abre (y queda abierta) cuando todas las fuentes
## de `fuentes` están cumplidas al mismo tiempo.


func fuentes() -> Array:
	return def.get("fuentes", [])


func all_fulfilled() -> bool:
	if fuentes().is_empty():
		return false
	for id in fuentes():
		var f = room.get_entity(str(id))
		if f == null or not f.is_fulfilled():
			return false
	return true


var opening := false


func _process(delta: float) -> void:
	super._process(delta)
	if not opening and not is_open() and all_fulfilled():
		opening = true
		open()
		Events.notify.emit("Promise.all: todas las promesas se cumplieron")


func _draw() -> void:
	super._draw()
	var font: Font = UITheme.mono_font()
	var done := 0
	for id in fuentes():
		var f = room.get_entity(str(id))
		if f and f.is_fulfilled():
			done += 1
	var text := "Promise.all([%d/%d])" % [done, fuentes().size()]
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	var col := Color(0.5, 2.2, 2.3) if is_open() else Color(2.4, 1.7, 0.5)
	draw_string(font, Vector2(-ts.x * 0.5, -h * TILE - 26), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
