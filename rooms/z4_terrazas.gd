extends RoomBase
## Sala 4 · Terrazas de la Rejilla: CSS Grid (pistas, fr, repeat, gap, áreas).
## Escalera flex en columna hacia el amuleto Gap.


func _init() -> void:
	zone = 4
	display_name = "Terrazas de la Rejilla"


func theme_name() -> String:
	return "canyon"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(14, 17, 57, 18)
	c.fill(26, 15, 57, 16)
	c.fill(38, 13, 57, 14)
	c.fill(48, 4, 51, 4)            # cornisa del amuleto
	c.fill(1, 1, 12, 4)
	c.fill(14, 1, 36, 2)
	c.door(0, 18, "W")
	c.door(57, 12, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "B")
	c.put(11, 18, "1")
	c.put(20, 16, "2")
	c.put(31, 14, "3")
	c.put(43, 12, "4")
	c.put(52, 3, "E")
	c.put(49, 3, "A")
	c.put(23, 16, "g")
	c.put(35, 14, "e")
	c.put(46, 8, "v")
	c.put(30, 14, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z4_caravana", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z4_atalaya", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L38"},
		"2": {"type": "tablilla", "id": "L39"},
		"3": {"type": "tablilla", "id": "L40"},
		"4": {"type": "tablilla", "id": "L41"},
		"E": {"type": "flex", "id": "escalera", "eje": "column", "propiedad": "justify-content", "largo": 10, "cruce": 3, "items": [1, 1, 1], "valor": "flex-end", "valores": ["flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly"]},
		"A": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "gap"},
		"g": {"type": "enemy", "kind": "guardia_important"},
		"e": {"type": "enemy", "kind": "float_errante"},
		"v": {"type": "enemy", "kind": "desbordamiento"},
		"x": {"type": "decor", "kind": "big_tag", "text": "grid-template-columns", "size": 70},
	}
