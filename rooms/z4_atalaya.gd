extends RoomBase
## Sala 5 · Atalaya Responsiva: diseño responsivo, media queries, macro y
## micro layouts. Sello S5.


func _init() -> void:
	zone = 4
	display_name = "Atalaya Responsiva"


func theme_name() -> String:
	return "canyon_night"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(56, 24).frame(21)
	c.fill(18, 19, 21, 20)
	c.fill(22, 17, 34, 20)
	c.fill(46, 1, 54, 16)
	c.fill(8, 1, 20, 9)
	c.fill(24, 1, 34, 6)
	c.door(0, 20, "W")
	c.door(55, 20, "D")
	c.put(3, 20, "M")
	c.put(8, 20, "1")
	c.put(15, 20, "2")
	c.put(28, 16, "3")
	c.put(40, 20, "4")
	c.put(50, 20, "S")
	c.put(12, 20, "r")
	c.put(44, 20, "g")
	c.put(31, 16, "x")
	c.put(53, 20, "A")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z4_terrazas", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z4_taller", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L42"},
		"2": {"type": "tablilla", "id": "L43"},
		"3": {"type": "tablilla", "id": "L44"},
		"4": {"type": "tablilla", "id": "L45"},
		"S": {"type": "sello", "id": "S5", "h": 4},
		"A": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "media_query"},
		"r": {"type": "enemy", "kind": "pixel_rigido"},
		"g": {"type": "enemy", "kind": "guardia_important"},
		"x": {"type": "decor", "kind": "big_tag", "text": "@media (min-width: 768px)", "size": 60},
	}
