extends RoomBase
## Sala 3 · Claro de Estilos: reglas CSS y modelo de cajas. Sello S2.
## Desvío con fragmento de máscara que enseña el pogo sobre pinchos.


func _init() -> void:
	zone = 3
	display_name = "Claro de Estilos"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(66, 22).frame(19)
	# Foso de pinchos: ramas de paso y, arriba, la rama del fragmento
	# (solo alcanzable rebotando con pogo sobre los pinchos).
	c.fill(20, 18, 31, 18, "^")
	c.fill(21, 18, 24, 18, "=")
	c.fill(27, 18, 30, 18, "=")
	c.fill(25, 14, 26, 14, "=")
	# Plataforma del modelo de cajas.
	c.fill(42, 17, 54, 18)
	# Techo del sello.
	c.fill(57, 1, 64, 14)
	c.fill(1, 1, 10, 5)
	c.fill(22, 1, 28, 3)
	c.door(0, 18, "W")
	c.door(65, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "0")
	c.put(10, 18, "1")
	c.put(13, 18, "2")
	c.put(34, 18, "3")
	c.put(44, 16, "4")
	c.put(51, 16, "5")
	c.put(48, 16, "x")
	c.put(25, 13, "F")
	c.put(17, 18, "i")
	c.put(38, 18, "e")
	c.put(28, 10, "v")
	c.put(46, 11, "v")
	c.put(56, 18, "z")
	c.put(53, 16, "c")
	c.put(60, 18, "S")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z3_galeria", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z3_tronco", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"0": {"type": "tablilla", "id": "L10"},
		"1": {"type": "tablilla", "id": "L11"},
		"2": {"type": "tablilla", "id": "L12"},
		"3": {"type": "tablilla", "id": "L13"},
		"4": {"type": "tablilla", "id": "L14"},
		"5": {"type": "tablilla", "id": "L15"},
		"x": {"type": "decor", "id": "box_model_decor", "kind": "box_model"},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"i": {"type": "sign", "text": "Opcional: en el aire mantén ↓ y pulsa X sobre los pinchos para rebotar"},
		"e": {"type": "enemy", "kind": "etiqueta_sin_cerrar"},
		"v": {"type": "enemy", "kind": "alt_ausente"},
		"z": {"type": "enemy", "kind": "nodo_zombi"},
		"c": {"type": "chest", "bits": 40},
		"S": {"type": "sello", "id": "S2", "h": 4},
	}
