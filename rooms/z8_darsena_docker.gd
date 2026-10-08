extends RoomBase
## Dársena de Imágenes Docker (Zona 8, Sala 2).

func _init() -> void:
	zone = 8
	display_name = "Dársena de Docker"

func theme_name() -> String:
	return "container_port"

func music() -> String:
	return "ruins"

func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 24).frame(21)
	c.fill(16, 20, 38, 20, "^")
	c.fill(20, 13, 30, 13)
	c.fill(50, 14, 58, 14)
	c.fill(8, 17, 13, 17, "=")
	c.fill(33, 15, 38, 15, "=")
	c.fill(42, 17, 47, 17, "=")
	c.door(0, 20, "d")
	c.door(61, 20, "D")
	c.put(12, 20, "t")    # L161
	c.put(27, 12, "u")   # L162
	c.put(54, 13, "v")   # L163
	c.put(56, 13, "c")   # Cofre
	c.put(38, 18, "z")
	c.put(45, 19, "f")
	c.put(49, 20, "o")
	c.put(18, 15, "b")
	c.put(2, 20, "M")   # El Manual
	# Escalones de acceso (el salto sube 2 filas como maximo).
	c.fill(14, 13, 18, 13, "=")
	c.fill(12, 15, 16, 15, "=")
	c.fill(4, 19, 8, 19, "=")
	c.fill(45, 15, 48, 15, "=")
	c.fill(32, 13, 35, 13, "=")
	c.fill(33, 17, 37, 17, "=")
	c.fill(35, 19, 39, 19, "=")
	return c.rows()

func legend() -> Dictionary:
	return {
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"d": {"type": "door", "id": "izq", "to": "z8_muelle", "to_door": "der"},
		"D": {"type": "door", "id": "der", "to": "z8_astillero_compose", "to_door": "izq"},
		"t": {"type": "tablilla", "id": "L161"},
		"u": {"type": "tablilla", "id": "L162"},
		"v": {"type": "tablilla", "id": "L163"},
		"c": {"type": "chest", "bits": 50},
		"z": {"type": "enemy", "kind": "pod_zombi"},
		"f": {"type": "enemy", "kind": "fuga_memoria"},
		"o": {"type": "enemy", "kind": "imagen_obsoleta"},
		"b": {"type": "enemy", "kind": "daemon_desbocado"}
	}
