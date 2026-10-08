extends RefCounted
## Pruebas de rutas y navegabilidad física para las salas de Zona 1.

var t

func test_z1_rooms_exist_and_compile() -> void:
	var rooms := ["z1_atrio", "z1_catacumbas", "z1_galeria", "z1_altar", "z1_boveda", "z1_cripta", "z1_bastion", "z1_arena"]
	for r in rooms:
		var script: GDScript = load("res://rooms/%s.gd" % r)
		t.ok(script != null, "Sala %s compila" % r)
		var inst: RoomBase = script.new()
		inst.room_id = r
		var rows := inst.layout()
		t.ok(rows.size() >= 17, "%s tiene al menos 17 filas" % r)
		t.ok(rows[0].length() >= 30, "%s tiene al menos 30 columnas" % r)
		inst.free()
