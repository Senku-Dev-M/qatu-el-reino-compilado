extends RefCounted
## Pruebas de rutas de Zona 2.

var t

func test_z2_rooms_exist_and_compile() -> void:
	var rooms := ["z2_torre_base", "z2_sala_flujo", "z2_galeria_spa", "z2_santuario_binding", "z2_terraza_mv", "z2_aguja_clean", "z2_mirador_frameworks", "z2_arena"]
	for r in rooms:
		var script: GDScript = load("res://rooms/%s.gd" % r)
		t.ok(script != null, "Sala %s compila" % r)
		var inst: RoomBase = script.new()
		inst.room_id = r
		var rows := inst.layout()
		t.ok(rows.size() >= 17, "%s tiene al menos 17 filas" % r)
		t.ok(rows[0].length() >= 30, "%s tiene al menos 30 columnas" % r)
		inst.free()
