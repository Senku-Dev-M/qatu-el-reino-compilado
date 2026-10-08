extends RoomBase
## Sala 4 · Tronco del DOM: santuario del Event Listener y primer ascenso.


func _init() -> void:
	zone = 3
	display_name = "Tronco del DOM"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(48, 20).frame(17)
	c.fill(43, 6, 46, 6)            # cornisa de salida
	c.fill(40, 6, 42, 6, "=")
	c.fill(1, 1, 20, 3)
	c.fill(21, 1, 26, 1)
	c.fill(16, 15, 19, 16)          # pedestal del santuario
	c.door(0, 16, "W")
	c.door(47, 5, "D")
	c.put(4, 16, "M")
	c.put(8, 16, "B")
	c.put(12, 16, "6")
	c.put(24, 16, "A")
	c.put(29, 16, "7")
	c.put(34, 16, "8")
	c.put(30, 11, "n")
	c.put(34, 8, "n")
	c.put(38, 5, "n")
	c.put(41, 14, "g")
	c.put(21, 16, "t")
	c.put(17, 14, "K")   # arma de la zona
	return c.rows()


func legend() -> Dictionary:
	return {
		"K": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "latigo_dom"},
		"W": {"type": "door", "id": "oeste", "to": "z3_claro", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z3_copa", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "event_listener", "dialog": "santuario_event_listener"},
		"6": {"type": "tablilla", "id": "L16"},
		"7": {"type": "tablilla", "id": "L17"},
		"8": {"type": "tablilla", "id": "L18"},
		"n": {"type": "anchor"},
		"g": {"type": "enemy", "kind": "listener_fantasma"},
		"t": {"type": "decor", "kind": "dom_tree"},
	}
