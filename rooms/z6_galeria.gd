extends RoomBase
## Sala 4 · Galería de Páginas: paginación por número, scroll infinito y
## cómo elegir. Puente obligatorio sobre tres fosos: cada tramo es una página
## (page[size]=3) y los atriles de los pilares muestran la siguiente.


func _init() -> void:
	zone = 6
	display_name = "Galería de Páginas"


func theme_name() -> String:
	return "archive"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 22).frame(19)
	for pit in [[20, 29], [33, 42], [46, 55]]:
		c.fill(pit[0], 19, pit[1], 20, ".")
		c.fill(pit[0], 20, pit[1], 20, "^")
	c.fill(1, 1, 14, 4)
	c.fill(18, 1, 44, 2)
	c.door(0, 18, "W")
	c.door(63, 18, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "1")
	c.put(17, 18, "a")
	c.put(19, 18, "E")
	c.put(31, 18, "b")
	c.put(44, 18, "c")
	c.put(58, 18, "2")
	c.put(61, 18, "3")
	c.put(12, 18, "n")
	c.put(38, 12, "o")
	c.put(59, 18, "x")
	c.put(15, 18, "K")   # arma de la zona (antes del primer foso)
	return c.rows()


func legend() -> Dictionary:
	return {
		"K": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "guadana_paginada"},
		"W": {"type": "door", "id": "oeste", "to": "z6_catalogo", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z6_sotano", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L82"},
		"2": {"type": "tablilla", "id": "L83"},
		"3": {"type": "tablilla", "id": "L84"},
		"E": {"type": "paginador", "id": "galeria", "tam": 3, "estilo": "jsonapi", "recurso": "cuadros", "items": [
			[2, 0, 2], [5, 0, 2], [8, 0, 2],
			[15, 0, 2], [18, 0, 2], [21, 0, 2],
			[28, 0, 2], [31, 0, 2], [34, 0, 2]]},
		"a": {"type": "atril", "id": "atril_1", "target": "galeria", "accion": "pagina", "pagina": 1},
		"b": {"type": "atril", "id": "atril_2", "target": "galeria", "accion": "pagina", "pagina": 2},
		"c": {"type": "atril", "id": "atril_3", "target": "galeria", "accion": "pagina", "pagina": 3},
		"n": {"type": "enemy", "kind": "consulta_n1"},
		"o": {"type": "enemy", "kind": "cache_obsoleta"},
		"x": {"type": "decor", "kind": "feed"},
	}
