extends RoomBase
## Sala 1 · Raíz <html>: entrada al bosque, banco y anatomía del documento.


func _init() -> void:
	zone = 3
	display_name = "Raíz <html>"
	area_title = "Bosque del DOM"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(56, 20).frame(17)
	c.fill(22, 15, 34, 16)          # bloque central
	c.fill(44, 6, 54, 6)            # cornisa del atajo
	c.fill(6, 15, 9, 15, "=")
	c.fill(10, 13, 14, 13, "=")
	c.fill(1, 1, 12, 3)             # techo irregular
	c.fill(30, 1, 40, 2)
	c.door(55, 16, "D")
	c.door(55, 5, "U")
	c.put(4, 16, "P")
	c.put(8, 16, "M")
	c.put(15, 16, "B")
	c.put(19, 16, "1")
	c.put(24, 14, "2")
	c.put(30, 14, "3")
	c.put(38, 16, "4")
	c.put(45, 16, "e")
	c.put(51, 16, "e")
	c.put(12, 12, "c")
	c.put(41, 11, "n")
	c.put(43, 5, "n")
	c.put(47, 16, "t")
	return c.rows()


func legend() -> Dictionary:
	return {
		"P": {"type": "portal", "id": "portal", "to": "hub_plaza", "to_door": "portal3", "prompt": "Volver a Qatu", "week": 3},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L01"},
		"2": {"type": "tablilla", "id": "L02"},
		"3": {"type": "tablilla", "id": "L03"},
		"4": {"type": "tablilla", "id": "L04"},
		"e": {"type": "enemy", "kind": "etiqueta_sin_cerrar"},
		"c": {"type": "chest", "bits": 30},
		"n": {"type": "anchor"},
		"t": {"type": "decor", "kind": "dom_tree"},
		"D": {"type": "door", "id": "este", "to": "z3_galeria", "to_door": "oeste"},
		"U": {"type": "door", "id": "atajo", "to": "z3_copa", "to_door": "atajo"},
	}
