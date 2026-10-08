extends RoomBase
## Sala 1 · Embarcadero de los Formularios: qué es un formulario, GET y POST,
## controles con name y label. Mapa de la zona.


func _init() -> void:
	zone = 5
	display_name = "Embarcadero de los Formularios"
	area_title = "Ríos Asíncronos"


func theme_name() -> String:
	return "river"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(54, 20).frame(17)
	c.fill(1, 1, 12, 3)
	c.fill(30, 1, 52, 2)
	c.fill(16, 15, 20, 15, "=")      # muelle alto con el mapa
	c.fill(30, 17, 32, 18, ".")      # canal
	c.fill(30, 18, 32, 18, "^")
	c.fill(35, 15, 42, 16)           # embarcadero de piedra
	c.door(53, 16, "D")
	c.put(4, 16, "P")
	c.put(8, 16, "M")
	c.put(12, 16, "B")
	c.put(18, 14, "m")
	c.put(22, 16, "1")
	c.put(27, 16, "2")
	c.put(39, 14, "3")
	c.put(14, 16, "t")
	c.put(26, 16, "x")
	c.put(47, 16, "p")
	return c.rows()


func legend() -> Dictionary:
	return {
		"P": {"type": "portal", "id": "portal", "to": "hub_plaza", "to_door": "portal5", "prompt": "Volver a Qatu", "week": 5},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"m": {"type": "pickup", "id": "mapa", "kind": "map"},
		"1": {"type": "tablilla", "id": "L49"},
		"2": {"type": "tablilla", "id": "L50"},
		"3": {"type": "tablilla", "id": "L51"},
		"t": {"type": "pipe", "largo": 14, "alto": 6, "peticion": "POST /registro", "respuesta": "201 Created"},
		"x": {"type": "decor", "kind": "big_tag", "text": "<form method=\"post\">", "size": 70},
		"p": {"type": "enemy", "kind": "peticion_pendiente"},
		"D": {"type": "door", "id": "este", "to": "z5_esclusas", "to_door": "oeste"},
	}
