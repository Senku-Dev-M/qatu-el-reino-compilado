extends RoomBase
## Sala 3 · Patio de las Concesiones: Authorization Code, Implicit, ROPC,
## Client Credentials y PKCE. Dos autorizadores con alcances distintos: el
## arco pide `vendedor` y con el token de `visitante` responde 403.


func _init() -> void:
	zone = 7
	display_name = "Patio de las Concesiones"


func theme_name() -> String:
	return "citadel"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(62, 24).frame(21)
	c.fill(44, 13, 61, 20)           # terraza alta
	c.fill(1, 1, 14, 4)
	c.fill(18, 1, 40, 2)
	c.door(0, 20, "W")
	c.door(61, 12, "D")
	c.put(3, 20, "M")
	c.put(8, 20, "1")
	c.put(14, 20, "2")
	c.put(20, 20, "3")
	c.put(26, 20, "U")
	c.put(31, 20, "V")
	c.put(36, 20, "L")
	c.put(40, 20, "T")
	c.put(50, 12, "4")
	c.put(24, 20, "f")
	c.put(34, 20, "p")
	c.put(56, 12, "x")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z7_barbacana", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z7_capilla", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L100"},
		"2": {"type": "tablilla", "id": "L101"},
		"3": {"type": "tablilla", "id": "L102"},
		"4": {"type": "tablilla", "id": "L103"},
		"U": {"type": "autorizador", "id": "autorizador_visitante", "scope": "visitante", "etiqueta": "/authorize?scope=visitante"},
		"V": {"type": "autorizador", "id": "autorizador_vendedor", "scope": "vendedor", "etiqueta": "/authorize?scope=vendedor"},
		"L": {"type": "lector", "id": "lector_vendedor", "scope": "vendedor", "h": 3},
		"T": {"type": "puente_token", "id": "puente_patio", "scope": "vendedor", "items": [[1, -2, 2], [-2, -4, 2], [1, -6, 2]]},
		"f": {"type": "enemy", "kind": "fuerza_bruta"},
		"p": {"type": "enemy", "kind": "portero_403"},
		"x": {"type": "decor", "kind": "big_tag", "text": "PKCE", "size": 110},
	}
