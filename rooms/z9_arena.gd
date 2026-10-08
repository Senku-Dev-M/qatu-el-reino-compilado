extends RoomBase
## Cámara de Depuración: Arena de La Regresión Crítica (Zona 9, Sala 8).

func _init() -> void:
	zone = 9
	display_name = "Cámara de Depuración"

func theme_name() -> String:
	return "qa_lab"

func music() -> String:
	return "boss"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(8, 14, 15, 14, "=")
	c.fill(42, 14, 49, 14, "=")
	c.fill(24, 10, 33, 10, "=")
	c.door(0, 18, "d")
	c.put(4, 18, "W")    # gate_w
	c.put(53, 18, "E")   # gate_e
	c.put(29, 18, "J")   # BossArena Regresion
	c.put(50, 18, "P")   # Portal de regreso
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "z9_galeria_metricas", "to_door": "der"},
		"W": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"E": {"type": "gate", "id": "gate_e", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"J": {
			"type": "boss",
			"id": "jefe_regresion",
			"kind": "regresion",
			"half_w": 18,
			"nombre": "La Regresión Crítica",
			"subtitulo": "Fallo Metamórfico de Seguridad",
			"musica_zona": "canyon",
			"recompensa": "Máscara de Seguridad y QA",
			"final": "final"
		},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "portal9", "prompt": "Volver a Qatu"}
	}
