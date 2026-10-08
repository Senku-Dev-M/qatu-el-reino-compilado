extends RoomBase
## Sala 2 · Estanterías de OData: qué es OData, $filter, $orderby, $top,
## $skip, $select y $count. Subida obligatoria por una estantería paginada
## ($top=3): cada atril muestra la página siguiente. Sello S10.


func _init() -> void:
	zone = 6
	display_name = "Estanterías de OData"


func theme_name() -> String:
	return "archive"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(60, 26).frame(23)
	c.fill(31, 15, 34, 22)           # pilar A (atril de la página 2)
	c.fill(45, 7, 48, 22)            # pilar B (atril de la página 3)
	c.fill(35, 22, 44, 22, "^")      # tinta derramada entre pilares
	c.fill(49, 22, 58, 22, "^")
	c.fill(58, 7, 58, 7)             # cornisa de salida
	c.fill(58, 1, 58, 2)             # techo del sello
	c.fill(1, 1, 18, 5)
	c.fill(22, 1, 40, 3)
	c.door(0, 22, "W")
	c.door(59, 6, "D")
	c.put(3, 22, "M")
	c.put(8, 22, "1")
	c.put(13, 22, "2")
	c.put(17, 22, "a")
	c.put(20, 22, "E")
	c.put(32, 14, "b")
	c.put(34, 14, "3")
	c.put(46, 6, "c")
	c.put(58, 6, "S")
	c.put(10, 22, "l")
	c.put(40, 6, "o")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z6_vestibulo", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z6_catalogo", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L77"},
		"2": {"type": "tablilla", "id": "L78"},
		"3": {"type": "tablilla", "id": "L79"},
		"E": {"type": "paginador", "id": "estantes", "tam": 3, "estilo": "odata", "recurso": "estantes", "items": [
			[2, -2, 2], [5, -4, 2], [8, -6, 2],
			[16, -10, 2], [19, -12, 2], [22, -14, 2],
			[30, -16, 2], [33, -16, 2], [36, -16, 2]]},
		"a": {"type": "atril", "id": "atril_1", "target": "estantes", "accion": "pagina", "pagina": 1},
		"b": {"type": "atril", "id": "atril_2", "target": "estantes", "accion": "pagina", "pagina": 2},
		"c": {"type": "atril", "id": "atril_3", "target": "estantes", "accion": "pagina", "pagina": 3},
		"S": {"type": "sello", "id": "S10", "h": 4},
		"l": {"type": "enemy", "kind": "log_sincrono"},
		"o": {"type": "enemy", "kind": "cache_obsoleta"},
	}
