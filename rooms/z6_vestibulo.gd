extends RoomBase
## Sala 1 · Vestíbulo del Índice: por qué filtrar, ordenar y paginar,
## parámetros de consulta y paginación offset/cursor. Mapa de la zona.


func _init() -> void:
	zone = 6
	display_name = "Vestíbulo del Índice"
	area_title = "Archivo Paginado"


func theme_name() -> String:
	return "archive"


func music() -> String:
	return "archive"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(54, 20).frame(17)
	c.fill(1, 1, 12, 3)
	c.fill(30, 1, 52, 2)
	c.fill(16, 15, 20, 15, "=")      # estante alto con el mapa
	c.door(53, 16, "D")
	c.put(4, 16, "P")
	c.put(8, 16, "M")
	c.put(12, 16, "B")
	c.put(18, 14, "m")
	c.put(22, 16, "1")
	c.put(28, 16, "2")
	c.put(40, 16, "3")
	c.put(34, 16, "x")
	c.put(44, 16, "t")
	c.put(47, 16, "n")
	return c.rows()


func legend() -> Dictionary:
	return {
		"P": {"type": "portal", "id": "portal", "to": "hub_plaza", "to_door": "portal6", "prompt": "Volver a Qatu", "week": 6},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"m": {"type": "pickup", "id": "mapa", "kind": "map"},
		"1": {"type": "tablilla", "id": "L74"},
		"2": {"type": "tablilla", "id": "L75"},
		"3": {"type": "tablilla", "id": "L76"},
		"x": {"type": "decor", "kind": "feed"},
		"t": {"type": "pipe", "largo": 8, "alto": 7, "peticion": "GET /productos?page=2", "respuesta": "200 OK · 20 items"},
		"n": {"type": "enemy", "kind": "consulta_n1"},
		"D": {"type": "door", "id": "este", "to": "z6_estanteria", "to_door": "oeste"},
	}
