extends RoomBase
## Cámara de Pruebas E2E y Selenium (Zona 9, Sala 3).

func _init() -> void:
	zone = 9
	display_name = "Cámara de Pruebas E2E"

func theme_name() -> String:
	return "qa_lab"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 24).frame(21)
	c.fill(16, 20, 38, 20, "^")
	c.fill(20, 13, 30, 13)
	c.fill(50, 14, 58, 14)
	c.fill(8, 17, 13, 17, "=")
	c.fill(33, 15, 38, 15, "=")
	c.fill(42, 17, 47, 17, "=")
	c.door(0, 20, "d")
	c.door(61, 20, "D")
	c.put(12, 20, "t")    # L185
	c.put(27, 12, "u")   # L186
	c.put(54, 13, "v")   # L187
	c.put(56, 13, "c")   # Cofre
	c.put(38, 18, "i")
	c.put(45, 19, "k")
	c.put(53, 13, "x")
	c.put(18, 15, "y")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(14, 13, 18, 13, "=")
	c.fill(12, 15, 16, 15, "=")
	c.fill(4, 19, 8, 19, "=")
	c.fill(45, 15, 48, 15, "=")
	c.fill(32, 13, 35, 13, "=")
	c.fill(33, 17, 37, 17, "=")
	c.fill(35, 19, 39, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z9_sala_piramide", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z9_santuario_inspector", "to_door": "izq"},
		"t": {"type": "tablilla", "id": "L185"},
		"u": {"type": "tablilla", "id": "L186"},
		"v": {"type": "tablilla", "id": "L187"},
		"c": {"type": "chest", "bits": 55},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
