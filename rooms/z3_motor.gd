extends RoomBase
## Sala 7 (oculta) · Cámara del Motor: motor de JavaScript y APIs del navegador.


func _init() -> void:
	zone = 3
	display_name = "Cámara del Motor"


func theme_name() -> String:
	return "engine"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(36, 18).frame(16)
	c.fill(4, 14, 8, 15)
	c.fill(1, 1, 10, 4)
	c.fill(26, 1, 34, 3)
	c.door(35, 15, "D")
	c.put(6, 13, "F")
	c.put(31, 15, "M")
	c.put(24, 15, "7")
	c.put(18, 15, "8")
	c.put(28, 15, "A")
	c.put(12, 15, "z")
	c.put(15, 15, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"D": {"type": "door", "id": "este", "to": "z3_copa", "to_door": "motor"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"7": {"type": "tablilla", "id": "L27"},
		"8": {"type": "tablilla", "id": "L28"},
		"A": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "delegacion"},
		"z": {"type": "enemy", "kind": "nodo_zombi"},
		"x": {"type": "decor", "kind": "big_tag", "text": "V8 · JIT", "size": 140},
	}
