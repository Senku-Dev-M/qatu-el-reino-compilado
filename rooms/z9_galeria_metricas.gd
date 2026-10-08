extends RoomBase
## Galería de Cobertura de Mutación (Zona 9, Sala 7). Sello S27 y Banco previo a La Regresión.

func _init() -> void:
	zone = 9
	display_name = "Galería de Métricas"

func theme_name() -> String:
	return "qa_lab"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	c.fill(16, 20, 36, 20, "^")
	c.fill(40, 13, 56, 20)
	c.fill(44, 7, 52, 7)
	c.put(48, 6, "S")    # Sello S27
	c.fill(8, 17, 12, 17, "=")
	c.fill(16, 14, 21, 14, "=")
	c.fill(26, 11, 31, 11, "=")
	c.fill(34, 8, 38, 8, "=")
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	c.put(46, 12, "B")
	c.put(11, 20, "t")    # L197
	c.put(20, 13, "u")   # L198
	c.put(52, 12, "v")   # L199
	c.put(15, 20, "i")
	c.put(10, 16, "k")
	c.put(36, 7, "x")
	c.put(22, 6, "y")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(38, 6, 42, 6, "=")
	c.fill(29, 9, 32, 9, "=")
	c.fill(22, 12, 24, 12, "=")
	c.fill(14, 16, 17, 16, "=")
	c.fill(4, 19, 8, 19, "=")
	c.fill(30, 13, 34, 13, "=")
	c.fill(34, 13, 38, 13, "=")
	c.fill(58, 13, 61, 13, "=")
	c.fill(58, 15, 61, 15, "=")
	c.fill(58, 17, 60, 17, "=")
	c.fill(58, 19, 60, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z9_torre_monitoreo", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z9_arena", "to_door": "izq"},
		"B": {"type": "bench", "id": "banco"},
		"S": {"type": "sello", "id": "S27", "h": 4},
		"t": {"type": "tablilla", "id": "L197"},
		"u": {"type": "tablilla", "id": "L198"},
		"v": {"type": "tablilla", "id": "L199"},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
