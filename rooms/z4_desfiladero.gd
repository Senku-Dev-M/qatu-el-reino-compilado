extends RoomBase
## Sala 2 · Desfiladero Flex: contenedor, ejes, justify-content y align-items.
## Santuario de la habilidad Flex y primer puente flex sobre un foso.


func _init() -> void:
	zone = 4
	display_name = "Desfiladero de los Ejes"


func theme_name() -> String:
	return "canyon"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	# Foso con pinchos que cruza el puente flex (x 38..51).
	c.fill(38, 19, 51, 20, ".")
	c.fill(38, 20, 51, 20, "^")
	c.fill(18, 17, 22, 18)          # pedestal del santuario
	c.fill(1, 1, 16, 4)
	c.fill(24, 1, 36, 3)
	c.fill(52, 1, 60, 5)
	c.door(0, 18, "W")
	c.door(61, 18, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "1")
	c.put(13, 18, "2")
	c.put(20, 16, "A")
	c.put(27, 18, "3")
	c.put(33, 18, "4")
	c.put(38, 19, "F")
	c.put(29, 12, "v")
	c.put(56, 12, "v")
	c.put(36, 18, "i")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z4_mirador", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z4_caravana", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L31"},
		"2": {"type": "tablilla", "id": "L32"},
		"3": {"type": "tablilla", "id": "L33"},
		"4": {"type": "tablilla", "id": "L34"},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "flex", "dialog": "santuario_flex"},
		"F": {"type": "flex", "id": "puente", "eje": "row", "propiedad": "justify-content", "largo": 14, "cruce": 1, "items": [3, 3], "valor": "flex-start", "valores": ["flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly"]},
		"v": {"type": "enemy", "kind": "desbordamiento"},
		"i": {"type": "sign", "text": "Pista: reparte el espacio libre entre las plataformas"},
	}
