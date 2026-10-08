extends RoomBase
## Sala 2 · Barbacana de los Tokens: OAuth 2.0, access token y refresh token.
## Santuario de la habilidad Tokens, primer autorizador, primer arco lector y
## un puente que solo existe mientras el token es válido. Sello S13.


func _init() -> void:
	zone = 7
	display_name = "Barbacana de los Tokens"


func theme_name() -> String:
	return "citadel"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(12, 17, 16, 18)           # pedestal del santuario
	c.fill(39, 19, 44, 20, ".")      # foso del puente de tokens
	c.fill(39, 20, 44, 20, "^")
	c.fill(46, 1, 50, 14)            # techo del sello
	c.fill(1, 1, 10, 4)
	c.fill(20, 1, 36, 2)
	c.door(0, 18, "W")
	c.door(57, 18, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "1")
	c.put(14, 16, "A")
	c.put(20, 18, "2")
	c.put(26, 18, "U")
	c.put(36, 18, "L")
	c.put(38, 18, "T")
	c.put(48, 18, "S")
	c.put(31, 12, "k")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z7_puesto", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z7_patio", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L98"},
		"2": {"type": "tablilla", "id": "L99"},
		"A": {"type": "pickup", "id": "santuario", "kind": "ability", "value": "token", "dialog": "santuario_token"},
		"U": {"type": "autorizador", "id": "autorizador_visitante", "scope": "visitante", "etiqueta": "/authorize"},
		"L": {"type": "lector", "id": "lector_visitante", "scope": "visitante", "h": 3},
		"T": {"type": "puente_token", "id": "puente_barbacana", "scope": "visitante", "items": [[1, 0, 2], [4, 0, 2]]},
		"S": {"type": "sello", "id": "S13", "h": 4},
		"k": {"type": "enemy", "kind": "token_robado"},
	}
