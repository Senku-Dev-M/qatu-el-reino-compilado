extends RoomBase
## Muelle de Carga (Zona 8, Sala 1).

func _init() -> void:
	zone = 8
	display_name = "Muelle de Carga"
	area_title = "Puerto de Contenedores"

func theme_name() -> String:
	return "container_port"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(20, 18, 34, 18, "^")
	c.fill(6, 13, 14, 13)
	c.fill(42, 12, 50, 12)
	c.fill(16, 17, 21, 17, "=")   # muelle bajo: se sube desde el suelo
	c.fill(24, 14, 30, 14, "=")
	c.fill(35, 15, 40, 15, "=")
	c.door(0, 18, "d")
	c.door(57, 18, "D")
	c.put(4, 18, "M")    # Manual
	c.put(8, 18, "B")    # Banco
	c.put(10, 12, "t")   # L158
	c.put(27, 13, "u")   # L159
	c.put(46, 11, "v")   # L160
	c.put(52, 18, "p")   # Mapa
	c.put(48, 11, "c")   # Cofre
	c.put(37, 18, "z")   # pod_zombi
	c.put(27, 17, "f")   # fuga_memoria
	c.put(41, 18, "o")   # imagen_obsoleta
	c.put(18, 14, "b")   # daemon_desbocado
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(37, 13, 40, 13, "=")
	c.fill(32, 13, 35, 13, "=")
	c.fill(19, 15, 22, 15, "=")
	c.fill(15, 15, 17, 15, "=")
	c.fill(31, 17, 35, 17, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"d": {"type": "door", "id": "izq", "to": "hub_plaza", "to_door": "portal8"},
		"D": {"type": "door", "id": "der", "to": "z8_darsena_docker", "to_door": "izq"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"t": {"type": "tablilla", "id": "L158"},
		"u": {"type": "tablilla", "id": "L159"},
		"v": {"type": "tablilla", "id": "L160"},
		"p": {"type": "pickup", "id": "mapa", "kind": "map"},
		"c": {"type": "chest", "bits": 45},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
