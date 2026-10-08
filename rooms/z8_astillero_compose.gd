extends RoomBase
## Astillero de Compose (Zona 8, Sala 3 - Sello S22 y Fragmento).

func _init() -> void:
	zone = 8
	display_name = "Astillero de Compose"

func theme_name() -> String:
	return "container_port"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(28, 5, 33, 5)
	c.fill(16, 18, 42, 18, "^")
	c.fill(8, 12, 18, 12)
	c.put(12, 11, "S")   # Sello S22
	c.fill(38, 11, 48, 11)
	c.fill(20, 15, 26, 15, "=")
	c.fill(30, 13, 36, 13, "=")
	c.door(0, 18, "d")
	c.door(57, 18, "D")
	c.door(30, 4, "U")
	c.put(6, 18, "t")    # L164
	c.put(23, 14, "u")   # L165
	c.put(44, 10, "v")   # L166
	c.put(46, 10, "F")   # Fragmento
	c.put(28, 12, "z")
	c.put(15, 11, "f")
	c.put(40, 10, "o")
	c.put(16, 7, "b")
	c.put(2, 18, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(34, 7, 37, 7, "=")
	c.fill(34, 9, 38, 9, "=")
	c.fill(25, 13, 28, 13, "=")
	c.fill(16, 17, 20, 17, "=")
	c.fill(12, 17, 16, 17, "=")
	c.fill(18, 5, 22, 5, "=")
	c.fill(22, 5, 26, 5, "=")
	c.fill(33, 15, 37, 15, "=")
	c.fill(35, 17, 39, 17, "=")
	c.fill(39, 17, 43, 17, "=")
	c.put(8, 11, "W")   # arma de la zona
	return c.rows()

func legend() -> Dictionary:
	return {
		"W": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "ancla_k8s"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z8_darsena_docker", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z8_santuario_pod", "to_door": "izq"},
		"U": {"type": "door", "id": "arr", "to": "z8_gruas_cicd", "to_door": "izq"},
		"S": {"type": "sello", "id": "S22", "h": 4},
		"t": {"type": "tablilla", "id": "L164"},
		"u": {"type": "tablilla", "id": "L165"},
		"v": {"type": "tablilla", "id": "L166"},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
