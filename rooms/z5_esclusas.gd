extends RoomBase
## Sala 2 · Esclusas de los Controles: input y sus tipos, textarea y select,
## fieldset, legend y envío. Esclusas escalonadas con canales. Sello S7.


func _init() -> void:
	zone = 5
	display_name = "Esclusas de los Controles"


func theme_name() -> String:
	return "river"


func music() -> String:
	return "river"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(60, 22).frame(19)
	c.fill(13, 19, 15, 20, ".")      # canal 1
	c.fill(13, 20, 15, 20, "^")
	c.fill(18, 17, 27, 18)           # primera esclusa
	c.fill(28, 19, 30, 20, ".")      # canal 2
	c.fill(28, 20, 30, 20, "^")
	c.fill(33, 17, 38, 18)           # esclusas escalonadas
	c.fill(39, 15, 44, 18)
	c.fill(50, 1, 54, 14)            # techo sobre el sello
	c.fill(1, 1, 10, 4)
	c.fill(20, 1, 40, 2)
	c.door(0, 18, "W")
	c.door(59, 18, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "1")
	c.put(22, 16, "2")
	c.put(41, 14, "3")
	c.put(52, 18, "S")
	c.put(35, 18, "x")
	c.put(24, 12, "p")
	c.put(47, 18, "s")
	c.put(27, 16, "K")   # arma de la zona
	return c.rows()


func legend() -> Dictionary:
	return {
		"K": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "arco_promesa"},
		"W": {"type": "door", "id": "oeste", "to": "z5_embarcadero", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z5_compuerta", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L52"},
		"2": {"type": "tablilla", "id": "L53"},
		"3": {"type": "tablilla", "id": "L54"},
		"S": {"type": "sello", "id": "S7", "h": 4},
		"x": {"type": "decor", "kind": "big_tag", "text": "<input type=\"email\">", "size": 70},
		"p": {"type": "enemy", "kind": "peticion_pendiente"},
		"s": {"type": "enemy", "kind": "script_inyectado"},
	}
