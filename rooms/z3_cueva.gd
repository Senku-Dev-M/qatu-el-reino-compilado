extends RoomBase
## Sala 6 · Cueva DevTools: La Depuradora, banco previo al jefe y Sello S3.


func _init() -> void:
	zone = 3
	display_name = "Cueva DevTools"


func theme_name() -> String:
	return "cave"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(56, 20).frame(17)
	c.fill(44, 1, 54, 12)
	c.fill(1, 1, 14, 5)
	c.fill(30, 15, 36, 16)
	c.put(28, 13, "n")
	c.fill(24, 11, 27, 11, "=")
	c.door(0, 16, "W")
	c.door(55, 16, "D")
	c.put(4, 16, "M")
	c.put(8, 16, "B")
	c.put(12, 16, "3")
	c.put(18, 16, "N")
	c.put(23, 16, "4")
	c.put(33, 14, "5")
	c.put(39, 16, "6")
	c.put(41, 16, "x")
	c.put(43, 16, "g")
	c.put(33, 9, "v")
	c.put(25, 10, "c")
	c.put(48, 16, "S")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z3_copa", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z3_arena", "to_door": "oeste"},
		"B": {"type": "bench", "id": "banco"},
		"N": {"type": "npc", "id": "depuradora", "who": "depuradora"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"3": {"type": "tablilla", "id": "L23"},
		"4": {"type": "tablilla", "id": "L24"},
		"5": {"type": "tablilla", "id": "L25"},
		"6": {"type": "tablilla", "id": "L26"},
		"x": {"type": "decor", "kind": "console"},
		"g": {"type": "enemy", "kind": "listener_fantasma"},
		"v": {"type": "enemy", "kind": "alt_ausente"},
		"c": {"type": "chest", "bits": 40},
		"n": {"type": "anchor"},
		"S": {"type": "sello", "id": "S3", "h": 4},
	}
