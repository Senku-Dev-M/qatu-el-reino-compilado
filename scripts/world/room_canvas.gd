class_name RoomCanvas
extends RefCounted
## Ayuda para construir layouts por coordenadas (x a la derecha, y hacia
## abajo, en tiles). Las coordenadas de `fill` son inclusivas.

var w := 0
var h := 0
var cells: Array = []


func _init(p_w: int, p_h: int) -> void:
	w = p_w
	h = p_h
	for y in h:
		var row := []
		row.resize(w)
		row.fill(".")
		cells.append(row)


## Techo, paredes laterales y suelo con la superficie en `floor_top`.
func frame(floor_top: int) -> RoomCanvas:
	fill(0, 0, w - 1, 0)
	fill(0, 0, 0, h - 1)
	fill(w - 1, 0, w - 1, h - 1)
	fill(0, floor_top, w - 1, h - 1)
	return self


func fill(x0: int, y0: int, x1: int, y1: int, ch := "#") -> RoomCanvas:
	for y in range(maxi(0, y0), mini(h - 1, y1) + 1):
		for x in range(maxi(0, x0), mini(w - 1, x1) + 1):
			cells[y][x] = ch
	return self


func put(x: int, y: int, ch: String) -> RoomCanvas:
	if x >= 0 and y >= 0 and x < w and y < h:
		cells[y][x] = ch
	return self


## Abre una puerta lateral: la celda (x, y) y `height - 1` celdas encima.
func door(x: int, y: int, ch: String, height := 3) -> RoomCanvas:
	fill(x, y - height + 1, x, y, ".")
	put(x, y, ch)
	return self


func rows() -> PackedStringArray:
	var out := PackedStringArray()
	for row in cells:
		out.append("".join(row))
	return out
