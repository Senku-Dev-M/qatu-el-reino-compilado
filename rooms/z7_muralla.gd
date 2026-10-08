extends RoomBase
## Sala 5 · Muralla de las Buenas Prácticas: clave de firma, datos sensibles,
## expiración y HTTPS, y reutilizar tokens. Puente largo de tokens con un
## ladrón al acecho: hay que renovar el access token a mitad de camino.


func _init() -> void:
	zone = 7
	display_name = "Muralla de las Buenas Prácticas"


func theme_name() -> String:
	return "citadel"


func music() -> String:
	return "citadel"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(60, 22).frame(19)
	c.fill(30, 19, 47, 20, ".")      # foso del adarve
	c.fill(30, 20, 47, 20, "^")
	c.fill(1, 1, 12, 4)
	c.fill(16, 1, 44, 2)
	c.door(0, 18, "W")
	c.door(59, 18, "D")
	c.put(3, 18, "M")
	c.put(8, 18, "1")
	c.put(16, 18, "2")
	c.put(24, 18, "3")
	c.put(28, 18, "U")
	c.put(29, 18, "T")
	c.put(52, 18, "A")
	c.put(38, 12, "k")
	c.put(56, 18, "e")
	return c.rows()


func legend() -> Dictionary:
	return {
		"W": {"type": "door", "id": "oeste", "to": "z7_capilla", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z7_torre", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"1": {"type": "tablilla", "id": "L107"},
		"2": {"type": "tablilla", "id": "L108"},
		"3": {"type": "tablilla", "id": "L109"},
		"U": {"type": "autorizador", "id": "autorizador_muralla", "scope": "visitante", "ttl": 8.0, "etiqueta": "/token (expira pronto)"},
		"T": {"type": "puente_token", "id": "puente_muralla", "scope": "visitante", "items": [[1, 0, 2], [4, 0, 2], [7, 0, 2], [10, 0, 2], [13, 0, 2], [16, 0, 2]]},
		"A": {"type": "pickup", "id": "amuleto", "kind": "charm", "value": "sso"},
		"k": {"type": "enemy", "kind": "token_robado"},
		"e": {"type": "enemy", "kind": "escalada_privilegios"},
	}
