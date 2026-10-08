extends RoomBase
## Grúas de Integración Continua (Zona 8, Sala 5). Sello S23.

func _init() -> void:
	zone = 8
	display_name = "Grúas de CI/CD"

func theme_name() -> String:
	return "container_port"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 24).frame(21)
	c.fill(16, 20, 44, 20, "^")
	c.fill(42, 8, 56, 8)
	c.put(48, 7, "S")    # Sello S23
	c.fill(8, 17, 13, 17, "=")
	c.fill(18, 14, 24, 14, "=")
	c.fill(28, 11, 34, 11, "=")
	c.fill(36, 9, 40, 9, "=")
	c.door(0, 20, "d")
	c.door(63, 20, "D")
	c.put(11, 20, "t")    # L170
	c.put(21, 13, "u")   # L171
	c.put(52, 7, "v")    # L172
	c.put(54, 7, "c")    # cofre
	c.put(40, 18, "z")
	c.put(10, 16, "f")
	c.put(43, 7, "o")
	c.put(18, 9, "b")
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
		"d": {"type": "door", "id": "izq", "to": "z8_astillero_compose", "to_door": "arr"},
		"D": {"type": "door", "id": "der", "to": "z8_hangar_k8s", "to_door": "izq"},
		"S": {"type": "sello", "id": "S23", "h": 4},
		"t": {"type": "tablilla", "id": "L170"},
		"u": {"type": "tablilla", "id": "L171"},
		"v": {"type": "tablilla", "id": "L172"},
		"c": {"type": "chest", "bits": 60},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
