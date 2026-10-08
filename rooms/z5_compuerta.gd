extends RoomBase
## Sala 3 · Compuerta de Seguridad: no confiar en el usuario, escapar
## caracteres y CSRF. Impostores y scripts inyectados. Pasaje oculto con fragmento.


func _init() -> void:
	zone = 5
	display_name = "Compuerta de Seguridad"


func theme_name() -> String:
	return "river"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(17, 17, 19, 17, "=")      # escalón hacia la compuerta
	c.fill(20, 15, 23, 18)           # muro de la compuerta
	c.fill(31, 19, 33, 20, ".")      # canal
	c.fill(31, 20, 33, 20, "^")
	c.fill(35, 17, 37, 17, "=")      # subida al pasaje alto
	c.fill(38, 15, 41, 15, "=")
	c.fill(42, 13, 46, 13)
	c.fill(47, 9, 56, 13)            # bloque con cámara oculta
	c.fill(47, 11, 54, 12, ".")      # cámara (2 filas) tras la pared falsa
	c.fill(1, 1, 12, 4)
	c.fill(24, 1, 40, 2)
	c.door(0, 18, "W")
	c.door(57, 18, "D")
	c.put(3, 18, "M")
	c.put(7, 18, "B")
	c.put(11, 18, "1")
	c.put(27, 18, "2")
	c.put(44, 18, "3")
	c.put(47, 12, "f")
	c.put(52, 12, "F")
	c.put(15, 18, "c")
	c.put(39, 18, "s")
	c.put(51, 18, "c")
	c.put(28, 18, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z5_esclusas", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z5_manantial", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L55"},
		"2": {"type": "tablilla", "id": "L56"},
		"3": {"type": "tablilla", "id": "L57"},
		"f": {"type": "fake_wall", "id": "pared_compuerta", "w": 2, "h": 2},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"c": {"type": "enemy", "kind": "csrf_impostor"},
		"s": {"type": "enemy", "kind": "script_inyectado"},
		"x": {"type": "decor", "kind": "big_tag", "text": "<script>", "size": 80},
	}
