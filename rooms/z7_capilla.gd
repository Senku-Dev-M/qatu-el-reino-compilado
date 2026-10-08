extends RoomBase
## Sala 4 · Capilla de la Identidad: OpenID Connect, el ID Token (JWT) y en
## qué se diferencia del access token. Sello S14 y cámara oculta con fragmento.


func _init() -> void:
	zone = 7
	display_name = "Capilla de la Identidad"


func theme_name() -> String:
	return "citadel_vault"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(58, 22).frame(19)
	c.fill(32, 1, 36, 14)            # techo del sello
	c.fill(40, 17, 42, 17, "=")      # subida a la cámara
	c.fill(43, 10, 56, 15)           # bloque de la cámara oculta
	c.fill(43, 12, 55, 14, ".")
	c.fill(1, 1, 8, 4)
	c.fill(12, 1, 28, 2)
	c.door(0, 18, "W")
	c.door(57, 18, "D")
	c.put(3, 18, "M")
	c.put(6, 18, "B")
	c.put(11, 18, "1")
	c.put(18, 18, "2")
	c.put(26, 18, "3")
	c.put(34, 18, "S")
	c.put(43, 14, "f")
	c.put(52, 14, "F")
	c.put(22, 12, "k")
	c.put(47, 18, "e")
	c.put(47, 14, "K")   # arma de la zona
	return c.rows()


func legend() -> Dictionary:
	return {
		"K": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "hoja_jwt"},
		"W": {"type": "door", "id": "oeste", "to": "z7_patio", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z7_muralla", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L104"},
		"2": {"type": "tablilla", "id": "L105"},
		"3": {"type": "tablilla", "id": "L106"},
		"S": {"type": "sello", "id": "S14", "h": 4},
		"f": {"type": "fake_wall", "id": "pared_capilla", "w": 1, "h": 3},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"k": {"type": "enemy", "kind": "token_robado"},
		"e": {"type": "enemy", "kind": "escalada_privilegios"},
	}
