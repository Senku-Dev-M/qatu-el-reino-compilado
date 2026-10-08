extends RoomBase
## Sala de la Pirámide de Pruebas (Zona 9, Sala 2). Sello S25.

func _init() -> void:
	zone = 9
	display_name = "Sala de la Pirámide"

func theme_name() -> String:
	return "qa_lab"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(25, 5, 30, 5)
	c.fill(16, 18, 42, 18, "^")
	c.fill(8, 12, 18, 12)
	c.put(12, 11, "S")   # Sello S25
	c.fill(38, 11, 48, 11)
	c.fill(20, 15, 26, 15, "=")
	c.fill(30, 13, 36, 13, "=")
	c.door(0, 18, "d")
	c.door(57, 18, "D")
	c.door(27, 4, "U")   # salida superior a bunker owasp
	c.put(11, 18, "t")    # L182
	c.put(23, 14, "u")   # L183
	c.put(44, 10, "v")   # L184
	c.put(30, 12, "i")
	c.put(15, 11, "k")
	c.put(41, 10, "x")
	c.put(16, 7, "y")
	c.put(2, 18, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(20, 6, 23, 6, "=")
	c.fill(18, 8, 22, 8, "=")
	c.fill(16, 10, 20, 10, "=")
	c.fill(3, 13, 6, 13, "=")
	c.fill(3, 15, 6, 15, "=")
	c.fill(4, 17, 7, 17, "=")
	c.fill(14, 17, 18, 17, "=")
	c.fill(33, 15, 37, 15, "=")
	c.fill(35, 17, 39, 17, "=")
	c.fill(39, 17, 43, 17, "=")
	c.put(48, 10, "W")   # arma de la zona
	return c.rows()

func legend() -> Dictionary:
	return {
		"W": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "bisturi_qa"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z9_vestibulo_qa", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z9_camara_selenium", "to_door": "izq"},
		"U": {"type": "door", "id": "arr", "to": "z9_bunker_owasp", "to_door": "izq"},
		"S": {"type": "sello", "id": "S25", "h": 4},
		"t": {"type": "tablilla", "id": "L182"},
		"u": {"type": "tablilla", "id": "L183"},
		"v": {"type": "tablilla", "id": "L184"},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
