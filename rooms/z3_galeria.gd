extends RoomBase
## Sala 2 · Galería de Etiquetas: elementos, atributos y anidamiento. Sello S1.


func _init() -> void:
	zone = 3
	display_name = "Galería de Etiquetas"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(64, 20).frame(17)
	# Foso con pinchos y plataformas.
	c.fill(21, 17, 31, 17, ".")
	c.fill(21, 18, 31, 18, "^")
	c.fill(24, 15, 25, 16)
	c.fill(28, 14, 29, 16)
	# Escalones de etiquetas.
	c.fill(36, 15, 40, 16)
	c.fill(42, 13, 46, 16)
	# Techo bajo y cierre del sello.
	c.fill(47, 1, 62, 7)
	c.fill(56, 8, 62, 12)
	c.fill(1, 1, 8, 4)
	c.door(0, 16, "W")
	c.door(63, 16, "D")
	c.put(3, 16, "M")
	c.put(7, 16, "5")
	c.put(12, 16, "6")
	c.put(17, 16, "7")
	c.put(37, 14, "8")
	c.put(44, 12, "9")
	c.put(34, 16, "e")
	c.put(54, 16, "e")
	c.put(51, 16, "s")
	c.put(40, 14, "c")
	c.put(58, 16, "S")
	c.put(48, 16, "g")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z3_raiz", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z3_claro", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"5": {"type": "tablilla", "id": "L05"},
		"6": {"type": "tablilla", "id": "L06"},
		"7": {"type": "tablilla", "id": "L07"},
		"8": {"type": "tablilla", "id": "L08"},
		"9": {"type": "tablilla", "id": "L09"},
		"e": {"type": "enemy", "kind": "etiqueta_sin_cerrar"},
		"s": {"type": "enemy", "kind": "selector_universal"},
		"c": {"type": "chest", "bits": 40},
		"S": {"type": "sello", "id": "S1", "h": 4},
		"g": {"type": "decor", "kind": "big_tag", "text": "<p><em></em></p>", "size": 110},
	}
