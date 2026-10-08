extends RoomBase
## Sala 6 · Torre del IdP: qué es IAM, el proveedor de identidad, SSO,
## identity brokering y social login. Un único token de `admin` abre los dos
## arcos de la torre: eso es Single Sign-On.


func _init() -> void:
	zone = 7
	display_name = "Torre del IdP"


func theme_name() -> String:
	return "citadel_vault"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(44, 28).frame(25)
	c.fill(22, 13, 43, 13)           # galería alta de la torre (a la derecha de la escalera)
	c.fill(1, 1, 10, 4)
	c.door(0, 24, "W")
	c.door(43, 12, "D")
	c.put(3, 24, "M")
	c.put(8, 24, "1")
	c.put(12, 24, "U")
	c.put(14, 24, "T")
	c.put(24, 12, "2")
	c.put(28, 12, "L")
	c.put(32, 12, "3")
	c.put(36, 12, "K")
	c.put(40, 12, "f")
	c.put(24, 24, "k")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z7_muralla", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z7_sesiones", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L110"},
		"2": {"type": "tablilla", "id": "L111"},
		"3": {"type": "tablilla", "id": "L112"},
		"U": {"type": "autorizador", "id": "idp", "scope": "admin", "ttl": 14.0, "etiqueta": "IdP · /authorize"},
		"T": {"type": "puente_token", "id": "escalera_idp", "scope": "admin", "items": [[2, -2, 3], [4, -4, 3], [2, -6, 3], [4, -8, 3], [2, -10, 3], [4, -12, 3]]},
		"L": {"type": "lector", "id": "lector_torre_1", "scope": "admin", "h": 3},
		"K": {"type": "lector", "id": "lector_torre_2", "scope": "admin", "h": 3},
		"f": {"type": "enemy", "kind": "fuerza_bruta"},
		"k": {"type": "enemy", "kind": "token_robado"},
	}
