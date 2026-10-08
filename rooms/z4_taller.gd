extends RoomBase
## Sala 6 · Taller de Frameworks: frameworks CSS, Tailwind y cuándo usar
## Flexbox o Grid. Banco antes del jefe, pasaje oculto con fragmento. Sello S6.


func _init() -> void:
	zone = 4
	display_name = "Taller de Frameworks"


func theme_name() -> String:
	return "canyon_night"


func music() -> String:
	return "canyon"


func layout() -> PackedStringArray:
	var c := RoomCanvas.new(50, 20).frame(17)
	c.fill(27, 15, 29, 15, "=")     # escalón de un sentido
	c.fill(30, 13, 42, 16)          # techo del taller
	c.fill(30, 14, 31, 16, ".")     # soportales
	c.fill(32, 14, 40, 16, ".")     # pared falsa y cámara oculta
	c.fill(44, 1, 48, 12)
	c.fill(1, 1, 14, 4)
	c.door(0, 16, "W")
	c.door(49, 16, "D")
	c.put(3, 16, "M")
	c.put(6, 16, "B")
	c.put(10, 16, "1")
	c.put(16, 16, "2")
	c.put(22, 16, "3")
	c.put(32, 16, "f")
	c.put(37, 16, "F")
	c.put(46, 16, "S")
	c.put(38, 12, "e")
	c.put(24, 8, "v")
	c.put(30, 12, "K")   # arma de la zona
	return c.rows()


func legend() -> Dictionary:
	return {
		"K": {"type": "pickup", "id": "arma", "kind": "weapon", "value": "dagas_flex"},
		"W": {"type": "door", "id": "oeste", "to": "z4_atalaya", "to_door": "este"},
		"D": {"type": "door", "id": "este", "to": "z4_arena", "to_door": "oeste"},
		"M": {"type": "npc", "id": "manual", "who": "manual"},
		"B": {"type": "bench", "id": "banco"},
		"1": {"type": "tablilla", "id": "L46"},
		"2": {"type": "tablilla", "id": "L47"},
		"3": {"type": "tablilla", "id": "L48"},
		"f": {"type": "fake_wall", "id": "pared_taller", "w": 2, "h": 3},
		"F": {"type": "pickup", "id": "fragmento", "kind": "shard"},
		"S": {"type": "sello", "id": "S6", "h": 4},
		"e": {"type": "enemy", "kind": "float_errante"},
		"v": {"type": "enemy", "kind": "desbordamiento"},
	}
