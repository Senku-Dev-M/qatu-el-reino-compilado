extends RoomBase
## Búnker de Vulnerabilidades OWASP (Zona 9, Sala 5). Sello S26.

func _init() -> void:
	zone = 9
	display_name = "Búnker OWASP"

func theme_name() -> String:
	return "security_vault"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	c.fill(16, 20, 44, 20, "^")
	c.fill(42, 8, 56, 8)
	c.put(48, 7, "S")    # Sello S26
	c.fill(8, 17, 13, 17, "=")
	c.fill(18, 14, 24, 14, "=")
	c.fill(28, 11, 34, 11, "=")
	c.fill(36, 9, 40, 9, "=")
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	c.put(11, 20, "t")    # L191
	c.put(21, 13, "u")   # L192
	c.put(52, 7, "v")    # L193
	c.put(54, 7, "c")    # cofre
	c.put(40, 18, "i")
	c.put(10, 16, "k")
	c.put(44, 7, "x")
	c.put(18, 9, "y")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(23, 12, 26, 12, "=")
	c.fill(13, 15, 16, 15, "=")
	c.fill(5, 19, 9, 19, "=")
	c.fill(31, 13, 35, 13, "=")
	c.fill(33, 15, 37, 15, "=")
	c.fill(35, 17, 39, 17, "=")
	c.fill(37, 19, 41, 19, "=")
	c.fill(41, 19, 45, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z9_sala_piramide", "to_door": "arr"},
		"D": {"type": "door", "id": "der", "to": "z9_torre_monitoreo", "to_door": "izq"},
		"S": {"type": "sello", "id": "S26", "h": 4},
		"t": {"type": "tablilla", "id": "L191"},
		"u": {"type": "tablilla", "id": "L192"},
		"v": {"type": "tablilla", "id": "L193"},
		"c": {"type": "chest", "bits": 65},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
