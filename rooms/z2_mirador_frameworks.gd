extends RoomBase
## Mirador de Frameworks Agnósticos (Zona 2, Sala 7). Sello S21 y Banco.

func _init() -> void:
	zone = 2
	display_name = "Mirador de Frameworks"

func theme_name() -> String:
	return "clean_arch"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	# Foso
	c.fill(16, 20, 36, 20, "^")
	# Estructura del mirador
	c.fill(40, 14, 54, 20)
	c.fill(44, 7, 52, 7)
	c.put(48, 6, "S")    # Sello S21
	# Escalada
	c.fill(8, 17, 12, 17, "=")
	c.fill(16, 14, 21, 14, "=")
	c.fill(26, 11, 31, 11, "=")
	c.fill(34, 8, 38, 8, "=")
	# Puertas
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	# Banco en zona segura
	c.put(46, 13, "B")
	# Tablillas
	c.put(11, 20, "t")    # L155
	c.put(20, 13, "u")   # L156
	c.put(50, 13, "v")   # L157
	# Enemigos
	c.put(15, 20, "a")
	c.put(10, 16, "r")
	c.put(60, 20, "l")
	c.put(35, 7, "w")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(38, 6, 42, 6, "=")
	c.fill(29, 9, 32, 9, "=")
	c.fill(22, 12, 24, 12, "=")
	c.fill(14, 16, 17, 16, "=")
	c.fill(4, 19, 8, 19, "=")
	c.fill(31, 13, 35, 13, "=")
	c.fill(34, 14, 38, 14, "=")
	c.fill(56, 15, 59, 15, "=")
	c.fill(56, 17, 59, 17, "=")
	c.fill(56, 19, 59, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z2_aguja_clean", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z2_arena", "to_door": "izq"},
		"B": {"type": "bench", "id": "banco"},
		"S": {"type": "sello", "id": "S21", "h": 4},
		"t": {"type": "tablilla", "id": "L155"},
		"u": {"type": "tablilla", "id": "L156"},
		"v": {"type": "tablilla", "id": "L157"},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
