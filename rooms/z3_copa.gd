extends RoomBase
## Sala 5 · Copa de los Eventos: ascenso vertical con nodos ancla,
## nodos *hover*, nodos *click*, atajo a la Raíz y pasaje oculto al Motor.


func _init() -> void:
	zone = 3
	display_name = "Copa de los Eventos"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(40, 44).frame(42)
	# L1 y plataformas hover (se dibujan como entidades).
	c.fill(26, 38, 36, 38)
	# L2
	c.fill(8, 30, 19, 30)
	# L3 (junto al pasaje oculto)
	c.fill(1, 21, 10, 21)
	# L4
	c.fill(14, 15, 28, 15)
	# L5 con hueco de subida de un sentido
	c.fill(1, 9, 26, 9)
	c.fill(27, 9, 30, 9, "=")
	c.fill(31, 9, 38, 9)
	# Techos que impiden saltar sobre las compuertas.
	c.fill(0, 1, 7, 5)
	c.fill(30, 1, 38, 5)
	c.fill(12, 1, 22, 2)
	# Paredes internas decorativas.
	c.fill(36, 20, 38, 30)
	c.fill(1, 32, 3, 36)
	c.door(0, 41, "W")
	c.door(0, 8, "U")
	c.door(0, 20, "M")
	c.door(39, 8, "D")
	# Pasaje oculto: pared falsa delante de la puerta del Motor.
	c.put(1, 20, "f")
	# Entidades.
	c.put(6, 41, "m")
	c.put(20, 41, "1")
	c.put(35, 37, "2")
	c.put(12, 29, "3")
	c.put(21, 14, "4")
	c.put(23, 37, "n")
	c.put(33, 34, "h")
	c.put(28, 36, "p")
	c.put(23, 34, "q")
	c.put(21, 32, "r")
	c.put(13, 25, "n")
	c.put(12, 20, "n")
	c.put(12, 15, "n")
	c.put(28, 10, "n")
	c.put(3, 8, "G")
	c.put(6, 7, "C")
	c.put(32, 8, "H")
	c.put(22, 7, "K")
	c.put(26, 14, "c")
	c.put(30, 40, "g")
	c.put(30, 26, "v")
	c.put(17, 14, "s")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z3_tronco", "to_door": "este"},
		"U": {"type": "door", "id": "atajo", "to": "z3_raiz", "to_door": "atajo"},
		"M": {"type": "door", "id": "motor", "to": "z3_motor", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z3_cueva", "to_door": "oeste"},
		"f": {"type": "fake_wall", "id": "pared_motor", "w": 2, "h": 3},
		"m": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L19"},
		"2": {"type": "tablilla", "id": "L20"},
		"3": {"type": "tablilla", "id": "L21"},
		"4": {"type": "tablilla", "id": "L22"},
		"n": {"type": "anchor"},
		"h": {"type": "hover_node", "id": "hover1", "radius": 480, "targets": ["hp1", "hp2", "hp3"]},
		"p": {"type": "hover_platform", "id": "hp1", "w": 3},
		"q": {"type": "hover_platform", "id": "hp2", "w": 3},
		"r": {"type": "hover_platform", "id": "hp3", "w": 3},
		"G": {"type": "gate", "id": "atajo_gate", "h": 3, "closed_dialog": "atajo_cerrado"},
		"C": {"type": "click_node", "id": "click_atajo", "target": "atajo_gate"},
		"H": {"type": "gate", "id": "salida_gate", "h": 3},
		"K": {"type": "click_node", "id": "click_salida", "target": "salida_gate"},
		"c": {"type": "chest", "bits": 50},
		"g": {"type": "enemy", "kind": "listener_fantasma"},
		"v": {"type": "enemy", "kind": "alt_ausente"},
		"s": {"type": "enemy", "kind": "selector_universal"},
	}
