extends RoomBase
## Sala 1 · Puesto de Control: autenticación y autorización, métodos de
## autenticación y control de acceso con RBAC y ABAC. Mapa de la zona.


func _init() -> void:
	zone = 7
	display_name = "Puesto de Control"
	area_title = "Ciudadela IAM"


func theme_name() -> String:
	return "citadel"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(54, 20).frame(17)
	c.fill(1, 1, 12, 3)
	c.fill(30, 1, 52, 2)
	c.fill(16, 15, 20, 15, "=")      # garita del mapa
	c.door(53, 16, "D")
	c.put(4, 16, "P")
	c.put(8, 16, "M")
	c.put(12, 16, "B")
	c.put(18, 14, "m")
	c.put(22, 16, "1")
	c.put(28, 16, "2")
	c.put(38, 16, "3")
	c.put(33, 16, "x")
	c.put(45, 16, "e")
	return c.rows()


func legend() -> Dictionary:
	return {
		"P": {"type": "portal", "id": "portal", "to": "hub_plaza", "to_door": "portal7", "prompt": "Volver a Qatu", "week": 7},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"m": {"type": "pickup", "id": "mapa", "kind": "map"},
		"1": {"type": "tablilla", "id": "L95"},
		"2": {"type": "tablilla", "id": "L96"},
		"3": {"type": "tablilla", "id": "L97"},
		"x": {"type": "decor", "kind": "big_tag", "text": "401 · 403", "size": 90},
		"e": {"type": "enemy", "kind": "escalada_privilegios"},
		"D": {"type": "door", "id": "este", "to": "z7_barbacana", "to_door": "oeste"},
	}
