extends RoomBase
## Vestíbulo de Aseguramiento de Calidad (Zona 9, Sala 1).

func _init() -> void:
	zone = 9
	display_name = "Vestíbulo de Aseguramiento"
	area_title = "Laboratorio de Pruebas"

func theme_name() -> String:
	return "qa_lab"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(20, 18, 34, 18, "^")
	c.fill(6, 12, 14, 12)
	c.fill(42, 11, 50, 11)
	c.fill(16, 16, 21, 16, "=")
	c.fill(24, 14, 30, 14, "=")
	c.fill(35, 15, 40, 15, "=")
	c.door(0, 18, "d")
	c.door(57, 18, "D")
	c.put(4, 18, "M")    # Manual
	c.put(8, 18, "B")    # Banco
	c.put(10, 11, "t")   # L179
	c.put(27, 13, "u")   # L180
	c.put(46, 10, "v")   # L181
	c.put(52, 18, "p")   # Mapa
	c.put(48, 10, "c")   # Cofre
	c.put(37, 18, "i")   # inyeccion_sql
	c.put(27, 17, "k")   # flaky_test
	c.put(44, 10, "x")   # xss_fantasma
	c.put(18, 15, "y")   # mutacion_silenciosa
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(38, 13, 41, 13, "=")
	c.fill(29, 12, 33, 12, "=")
	c.fill(19, 14, 22, 14, "=")
	c.fill(11, 17, 14, 17, "=")
	c.fill(15, 14, 17, 14, "=")
	c.fill(32, 17, 36, 17, "=")
	c.fill(27, 16, 30, 16, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "hub_plaza", "to_door": "portal9"},
		"D": {"type": "door", "id": "der", "to": "z9_sala_piramide", "to_door": "izq"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"t": {"type": "tablilla", "id": "L179"},
		"u": {"type": "tablilla", "id": "L180"},
		"v": {"type": "tablilla", "id": "L181"},
		"p": {"type": "pickup", "id": "mapa", "kind": "map"},
		"c": {"type": "chest", "bits": 50},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
