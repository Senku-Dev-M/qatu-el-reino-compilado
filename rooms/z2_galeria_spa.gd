extends RoomBase
## Galería de la Arquitectura Limpia (Zona 2, Sala 3). Sello S19.
## Santuario superior con plataformas de desacoplamiento y foso.

func _init() -> void:
	zone = 2
	display_name = "Galería de la Arquitectura Limpia"

func theme_name() -> String:
	return "clean_arch"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	# Foso
	c.fill(16, 20, 44, 20, "^")
	# Santuario elevado Sello S19
	c.fill(46, 8, 58, 8)
	c.put(52, 7, "S")
	# Plataformas
	c.fill(8, 17, 13, 17, "=")
	c.fill(18, 15, 24, 15, "=")
	c.fill(28, 12, 34, 12, "=")
	c.fill(38, 10, 43, 10, "=")
	# Puertas
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	# Tablillas
	c.put(11, 20, "t")    # L143
	c.put(21, 14, "u")   # L144
	c.put(31, 11, "v")   # L145
	c.put(55, 7, "c")    # cofre
	# Enemigos
	c.put(26, 12, "a")
	c.put(11, 16, "r")
	c.put(39, 9, "l")
	c.put(49, 20, "w")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(40, 8, 44, 8, "=")
	c.fill(33, 10, 36, 10, "=")
	c.fill(23, 13, 26, 13, "=")
	c.fill(13, 15, 16, 15, "=")
	c.fill(5, 19, 9, 19, "=")
	c.fill(34, 14, 38, 14, "=")
	c.fill(36, 16, 40, 16, "=")
	c.fill(38, 18, 42, 18, "=")
	c.fill(41, 19, 45, 19, "=")
	c.put(46, 7, "W")   # arma de la zona
	return c.rows()

func legend() -> Dictionary:
	return {
		"W": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "mazo_mvc"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z2_sala_flujo", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z2_santuario_binding", "to_door": "izq"},
		"S": {"type": "sello", "id": "S19", "h": 4},
		"t": {"type": "tablilla", "id": "L143"},
		"u": {"type": "tablilla", "id": "L144"},
		"v": {"type": "tablilla", "id": "L145"},
		"c": {"type": "chest", "bits": 50},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
