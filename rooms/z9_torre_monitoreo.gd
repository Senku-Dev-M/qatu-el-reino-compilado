extends RoomBase
## Torre de DevSecOps y Monitoreo (Zona 9, Sala 6).

func _init() -> void:
	zone = 9
	display_name = "Torre de Monitoreo"

func theme_name() -> String:
	return "security_vault"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 22).frame(19)
	c.fill(16, 18, 44, 18, "^")
	c.fill(22, 12, 34, 12)
	c.fill(10, 15, 15, 15, "=")
	c.fill(40, 15, 46, 15, "=")
	c.door(0, 18, "d")
	c.door(61, 18, "D")
	c.put(60, 18, "G")   # OwaspBarrier
	c.put(12, 18, "t")    # L194
	c.put(27, 11, "u")   # L195
	c.put(52, 18, "v")   # L196
	c.put(15, 18, "i")
	c.put(14, 14, "k")
	c.put(43, 14, "x")
	c.put(22, 8, "y")
	c.put(31, 11, "Q")   # aserción del WAF
	c.put(2, 18, "M")   # El Manual
	c.put(24, 11, "h")   # letrero con la tecla
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(16, 11, 20, 11, "=")
	c.fill(14, 13, 18, 13, "=")
	c.fill(6, 17, 10, 17, "=")
	c.fill(34, 10, 38, 10, "=")
	c.fill(35, 14, 38, 14, "=")
	c.fill(35, 15, 38, 15, "=")
	c.fill(41, 17, 45, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"h": {"type": "sign", "text": "Una aserción oculta protege la barrera: búscala con {inspector}", "ancho": 260},
		"Q": {"type": "assert_node", "id": "assert1", "target": "barrier1", "texto": "assert(entrada.saneada)"},
		"d": {"type": "door", "id": "izq", "to": "z9_bunker_owasp", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z9_galeria_metricas", "to_door": "izq"},
		"G": {"type": "owasp_barrier", "id": "barrier1", "h": 3},
		"t": {"type": "tablilla", "id": "L194"},
		"u": {"type": "tablilla", "id": "L195"},
		"v": {"type": "tablilla", "id": "L196"},
		"i": {"type": "enemy", "kind": "inyeccion_sql"},
		"k": {"type": "enemy", "kind": "flaky_test"},
		"x": {"type": "enemy", "kind": "xss_fantasma"},
		"y": {"type": "enemy", "kind": "mutacion_silenciosa"}
	}
