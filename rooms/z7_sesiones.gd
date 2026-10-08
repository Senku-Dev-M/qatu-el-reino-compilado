extends RoomBase
## Sala 7 · Sala de Sesiones: dónde guardar los tokens en el frontend, el
## papel del refresh token y sesión frente a JWT. Aquí no hay autorizador:
## el arco final se pasa renovando el access token con el refresh. Sello S15.


func _init() -> void:
	zone = 7
	display_name = "Sala de Sesiones"


func theme_name() -> String:
	return "citadel"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(32, 19, 37, 20, ".")
	c.fill(32, 20, 37, 20, "^")
	c.fill(48, 1, 52, 14)            # techo del sello
	c.fill(1, 1, 12, 4)
	c.fill(16, 1, 30, 2)
	c.door(0, 18, "W")
	c.door(57, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "B")
	c.put(11, 18, "1")
	c.put(18, 18, "2")
	c.put(26, 18, "3")
	c.put(31, 18, "T")
	c.put(41, 18, "L")
	c.put(50, 18, "S")
	c.put(14, 18, "e")
	c.put(45, 18, "p")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z7_torre", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z7_arena", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L113"},
		"2": {"type": "tablilla", "id": "L114"},
		"3": {"type": "tablilla", "id": "L115"},
		"T": {"type": "puente_token", "id": "puente_sesiones", "items": [[1, 0, 2], [4, 0, 2]]},
		"L": {"type": "lector", "id": "lector_sesiones", "scope": "admin", "h": 3},
		"S": {"type": "sello", "id": "S15", "h": 4},
		"e": {"type": "enemy", "kind": "escalada_privilegios"},
		"p": {"type": "enemy", "kind": "portero_403"},
	}
