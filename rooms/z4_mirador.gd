extends RoomBase
## Sala 1 · Mirador del Flujo: entrada a los cañones, flujo normal y block/inline.


func _init() -> void:
	zone = 4
	display_name = "Mirador del Flujo"
	area_title = "Cañones Flexibles"


func theme_name() -> String:
	return "canyon"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(52, 20).frame(17)
	c.fill(27, 15, 34, 16)
	c.fill(1, 1, 10, 3)
	c.fill(36, 1, 50, 2)
	c.fill(18, 15, 22, 15, "=")
	c.door(51, 16, "D")
	c.put(4, 16, "P")
	c.put(8, 16, "M")
	c.put(13, 16, "B")
	c.put(20, 14, "m")
	c.put(23, 16, "1")
	c.put(30, 14, "2")
	c.put(40, 16, "e")
	c.put(46, 16, "e")
	c.put(43, 16, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"P": {"type": "portal", "id": "portal", "to": "hub_plaza", "to_door": "portal4", "prompt": "Volver a Qatu", "week": 4},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"m": {"type": "pickup", "id": "mapa", "kind": "map"},
		"1": {"type": "tablilla", "id": "L29"},
		"2": {"type": "tablilla", "id": "L30"},
		"e": {"type": "enemy", "kind": "float_errante"},
		"x": {"type": "decor", "kind": "big_tag", "text": "display: flex;", "size": 90},
		"D": {"type": "door", "id": "este", "to": "z4_desfiladero", "to_door": "oeste"},
	}
