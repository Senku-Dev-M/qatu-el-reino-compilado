extends RoomBase
## Sala 7 · Anfiteatro del Parcial: arena del Guardián del Parcial con dos
## contenedores flex que el jefe desordena.


func _init() -> void:
	zone = 4
	display_name = "Anfiteatro del Parcial"


func theme_name() -> String:
	return "canyon_night"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(40, 22).frame(19)
	c.fill(1, 1, 8, 3)
	c.fill(31, 1, 38, 3)
	c.fill(14, 1, 25, 1)
	c.door(0, 18, "W")
	c.put(2, 18, "G")
	c.put(3, 17, "b")
	c.put(3, 15, "a")
	c.put(20, 18, "X")
	c.put(35, 18, "P")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z4_taller", "to_door": "este"},
		"G": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"b": {"type": "flex", "id": "flex_bajo", "eje": "row", "propiedad": "justify-content", "largo": 34, "cruce": 1, "items": [4, 4], "valor": "space-between", "persistente": false, "valores": ["flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly"]},
		"a": {"type": "flex", "id": "flex_alto", "eje": "row", "propiedad": "justify-content", "largo": 34, "cruce": 1, "items": [4], "valor": "center", "persistente": false, "valores": ["flex-start", "center", "flex-end"]},
		"X": {"type": "boss", "id": "arena", "kind": "guardian_parcial", "half_w": 17, "nombre": "El Guardián del Parcial", "subtitulo": "Jefe de los Cañones Flexibles", "recompensa": "Máscara del Parcial", "final": "final_z4"},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal4", "prompt": "Volver a Qatu", "requires_flag": "jefe:guardian_parcial", "week": 4},
	}
