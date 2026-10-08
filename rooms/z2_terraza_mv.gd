extends RoomBase
## Terraza del Patrón MVVM / MVC (Zona 2, Sala 5). Sello S20.
## Balcón exterior con plataformas ascendentes al aire libre.

func _init() -> void:
	zone = 2
	display_name = "Terraza MVVM"

func theme_name() -> String:
	return "towers"

func music() -> String:
	return "canyon"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	# Foso
	c.fill(14, 20, 36, 20, "^")
	# Torre de la vista y el modelo
	c.fill(40, 13, 52, 20)
	c.fill(42, 7, 50, 7)
	c.put(46, 6, "S")    # Sello S20
	# Escalones
	c.fill(8, 17, 12, 17, "=")
	c.fill(16, 14, 21, 14, "=")
	c.fill(25, 11, 30, 11, "=")
	c.fill(34, 9, 38, 9, "=")
	# Puertas
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	# Tablillas
	c.put(6, 20, "t")    # L149
	c.put(20, 13, "u")   # L150
	c.put(45, 12, "v")   # L151
	c.put(48, 6, "c")    # cofre
	# Enemigos
	c.put(13, 20, "a")
	c.put(10, 16, "r")
	c.put(35, 8, "l")
	c.put(58, 20, "w")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(36, 7, 40, 7, "=")
	c.fill(28, 9, 32, 9, "=")
	c.fill(23, 13, 26, 13, "=")
	c.fill(14, 16, 17, 16, "=")
	c.fill(8, 19, 11, 19, "=")
	c.fill(36, 11, 40, 11, "=")
	c.fill(54, 13, 57, 13, "=")
	c.fill(54, 15, 57, 15, "=")
	c.fill(54, 17, 57, 17, "=")
	c.fill(54, 19, 57, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z2_santuario_binding", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z2_aguja_clean", "to_door": "izq"},
		"S": {"type": "sello", "id": "S20", "h": 4},
		"t": {"type": "tablilla", "id": "L149"},
		"u": {"type": "tablilla", "id": "L150"},
		"v": {"type": "tablilla", "id": "L151"},
		"c": {"type": "chest", "bits": 60},
		"a": {"type": "enemy", "kind": "acoplamiento_rigido"},
		"r": {"type": "enemy", "kind": "render_bloqueante"},
		"l": {"type": "enemy", "kind": "logica_en_vista"},
		"w": {"type": "enemy", "kind": "framework_obsoleto"}
	}
