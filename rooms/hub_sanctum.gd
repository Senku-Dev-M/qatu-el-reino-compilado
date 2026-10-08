extends RoomBase
## Sanctum del Capstone Final (Zona 10).

func _init() -> void:
	zone = 10
	display_name = "Sanctum del Capstone"
	area_title = "Sanctum del Capstone"

func theme_name() -> String:
	return "hub_restored"

func music() -> String:
	return "boss"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(68, 24).frame(21)
	c.fill(10, 10, 20, 10)
	c.fill(48, 10, 58, 10)
	c.fill(26, 7, 42, 7)
	c.fill(12, 16, 18, 16, "=")
	c.fill(50, 16, 56, 16, "=")
	c.fill(28, 13, 40, 13, "=")
	c.door(0, 20, "d")
	c.put(5, 20, "W")
	c.put(62, 20, "E")
	c.put(34, 6, "S")    # Sello S28
	c.put(8, 20, "B")    # Banco
	c.put(14, 9, "0")    # L200
	c.put(18, 9, "1")    # L201
	c.put(29, 6, "2")    # L202
	c.put(39, 6, "3")    # L203
	c.put(51, 9, "4")    # L204
	c.put(55, 9, "5")    # L205
	c.put(34, 20, "J")   # DemoFinal
	c.put(59, 20, "P")   # Portal
	c.put(22, 4, "n")
	c.put(46, 4, "n")
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(22, 9, 25, 9, "=")
	c.fill(24, 11, 28, 11, "=")
	c.fill(24, 15, 28, 15, "=")
	c.fill(22, 17, 26, 17, "=")
	c.fill(20, 19, 24, 19, "=")
	c.fill(42, 5, 46, 5, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "hub_plaza", "to_door": "portal_sanctum"},
		"W": {"type": "gate", "id": "gate_w", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"E": {"type": "gate", "id": "gate_e", "h": 3, "start_open": true, "persist": false, "style": "arena"},
		"B": {"type": "bench", "id": "banco"},
		"S": {"type": "sello", "id": "S28", "h": 4},
		"0": {"type": "tablilla", "id": "L200"},
		"1": {"type": "tablilla", "id": "L201"},
		"2": {"type": "tablilla", "id": "L202"},
		"3": {"type": "tablilla", "id": "L203"},
		"4": {"type": "tablilla", "id": "L204"},
		"5": {"type": "tablilla", "id": "L205"},
		"J": {
			"type": "boss",
			"id": "jefe_demo_final",
			"kind": "demo_final",
			"half_w": 22,
			"nombre": "La Demo Final",
			"subtitulo": "Prueba Máxima del Ingeniero de Software",
			"musica_zona": "hub_theme",
			"recompensa": "Corona del Ingeniero de Software",
			"final": "final"
		},
		"P": {"type": "portal", "id": "portal_regreso", "to": "hub_plaza", "to_door": "inicio", "prompt": "Victoria Final"},
		"n": {"type": "anchor"}
	}
