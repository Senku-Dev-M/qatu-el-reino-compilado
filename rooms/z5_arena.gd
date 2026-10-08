extends RoomBase
## Sala 8 · Remolino del Callback: arena de Callback Hell con dos cadenas de
## promesas (.then) que suben hasta el núcleo del jefe.


func _init() -> void:
	zone = 5
	display_name = "Remolino del Callback"


func theme_name() -> String:
	return "river_deep"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(40, 22).frame(19)
	c.fill(1, 1, 8, 3)
	c.fill(31, 1, 38, 3)
	c.fill(14, 1, 25, 1)
	c.door(0, 18, "W")
	c.put(2, 18, "G")
	c.put(6, 18, "1")
	c.put(14, 18, "2")
	c.put(19, 18, "3")
	c.put(25, 18, "5")
	c.put(34, 18, "4")
	c.put(20, 18, "X")
	c.put(37, 18, "P")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z5_observatorio", "to_door": "este"},
		"G": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"1": {"type": "promesa", "id": "cadena1", "etiqueta": "subir()", "plataformas": [[3, -2, 3]], "retardo": 1.0, "duracion": 7.0, "then": "cadena2"},
		"2": {"type": "promesa", "id": "cadena2", "etiqueta": ".then(subir)", "activable": false, "plataformas": [[0, -4, 3]], "retardo": 0.8, "duracion": 7.0, "then": "cadena3"},
		"3": {"type": "promesa", "id": "cadena3", "etiqueta": ".then(atacar)", "activable": false, "plataformas": [[-1, -6, 3]], "retardo": 0.8, "duracion": 7.0},
		"4": {"type": "promesa", "id": "cadena4", "etiqueta": "subir()", "plataformas": [[-6, -2, 3]], "retardo": 1.0, "duracion": 7.0, "then": "cadena5"},
		"5": {"type": "promesa", "id": "cadena5", "etiqueta": ".then(subir)", "activable": false, "plataformas": [[-2, -4, 3]], "retardo": 0.8, "duracion": 7.0, "then": "cadena3"},
		"X": {"type": "boss", "id": "arena", "kind": "callback_hell", "half_w": 17, "nombre": "Callback Hell", "subtitulo": "Jefe de los Ríos Asíncronos", "recompensa": "Máscara del Remolino", "final": "final_z5"},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal5", "prompt": "Volver a Qatu", "requires_flag": "jefe:callback_hell", "week": 5},
	}
