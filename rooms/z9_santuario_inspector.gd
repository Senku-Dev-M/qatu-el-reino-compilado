extends RoomBase
## Santuario del Inspector de Pruebas (Zona 9, Sala 4).

func _init() -> void:
	zone = 9
	display_name = "Santuario del Inspector"

func theme_name() -> String:
	return "qa_lab"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(16, 18, 42, 18, "^")
	c.fill(22, 12, 36, 12)
	c.fill(8, 15, 14, 15, "=")
	c.fill(44, 15, 50, 15, "=")
	c.door(0, 18, "d")
	c.put(34, 11, "c")
	c.put(6, 18, "t")    # L188
	c.put(27, 11, "u")   # L189
	c.put(52, 18, "v")   # L190
	c.put(15, 16, "i")
	c.put(30, 11, "k")
	c.put(46, 14, "x")
	c.put(18, 7, "y")
	c.put(11, 18, "A")   # habilidad Inspector
	c.put(24, 11, "Q")   # aserción de práctica
	c.put(2, 18, "M")   # El Manual
	c.put(46, 18, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(16, 11, 20, 11, "=")
	c.fill(14, 13, 18, 13, "=")
	c.fill(13, 17, 16, 17, "=")
	c.fill(38, 11, 41, 11, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Pulsa {inspector}: el Inspector revela aserciones ocultas", "ancho": 260},
		"Q": {"type": "assert_node", "id": "assert_practica", "texto": "assert(total >= 0)"},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "inspector", "dialog": "santuario_inspector"},
		"d": {"type": "door", "id": "izq", "to": "z9_camara_selenium", "to_door": "der"},
		"t": {"type": "tablilla", "id": "L188"},
		"u": {"type": "tablilla", "id": "L189"},
		"v": {"type": "tablilla", "id": "L190"},
		"c": {"type": "chest", "bits": 60},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
