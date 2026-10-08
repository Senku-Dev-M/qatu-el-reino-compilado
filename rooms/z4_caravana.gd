extends RoomBase
## Sala 3 · Paso de la Caravana: flex-wrap, flex-grow y contenedores anidados.
## Elevador flex en columna y puente con align-items bajo un techo bajo. Sello S4.


func _init() -> void:
	zone = 4
	display_name = "Paso de la Caravana"


func theme_name() -> String:
	return "canyon"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 26).frame(23)
	c.fill(23, 14, 44, 22)          # meseta central (se sube con el elevador)
	c.fill(45, 1, 54, 11)           # techo bajo sobre el puente align-items
	c.fill(45, 22, 54, 22, "^")     # pinchos al fondo del cañón
	c.fill(55, 14, 61, 22)          # cornisa de salida
	c.fill(55, 1, 60, 9)
	c.fill(5, 1, 18, 8)
	c.fill(1, 11, 4, 11)            # cornisa secreta (fragmento)
	c.door(0, 22, "W")
	c.door(61, 13, "D")
	c.put(3, 22, "M")
	c.put(7, 22, "1")
	c.put(13, 22, "2")
	c.put(30, 13, "3")
	c.put(20, 13, "E")
	c.put(45, 12, "P")
	c.put(58, 13, "S")
	c.put(2, 10, "F")
	c.put(8, 18, "n")
	c.put(5, 14, "n")
	c.put(10, 22, "r")
	c.put(36, 13, "e")
	c.put(40, 10, "v")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z4_desfiladero", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z4_terrazas", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L35"},
		"2": {"type": "tablilla", "id": "L36"},
		"3": {"type": "tablilla", "id": "L37"},
		"E": {"type": "flex", "id": "elevador", "eje": "column", "propiedad": "justify-content", "largo": 10, "cruce": 3, "items": [1, 1, 1], "valor": "flex-start", "valores": ["flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly"]},
		"P": {"type": "flex", "id": "puente_align", "eje": "row", "propiedad": "align-items", "largo": 10, "cruce": 4, "items": [2, 2, 2], "justify_fijo": "space-evenly", "valor": "stretch", "valores": ["flex-start", "center", "flex-end", "stretch"]},
		"S": {"type": "sello", "id": "S4", "h": 4},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"n": {"type": "anchor"},
		"r": {"type": "enemy", "kind": "pixel_rigido"},
		"e": {"type": "enemy", "kind": "float_errante"},
		"v": {"type": "enemy", "kind": "desbordamiento"},
	}
