extends RefCounted
## Pruebas de rutas y navegabilidad física para las salas de Zona 8.

var t

func test_z8_rooms_exist_and_compile() -> void:
	var rooms := [
		"z8_muelle", "z8_darsena_docker", "z8_astillero_compose", "z8_santuario_pod",
		"z8_gruas_cicd", "z8_hangar_k8s", "z8_faro_swarm", "z8_arena"
	]
	for r in rooms:
		var script: GDScript = load("res://rooms/%s.gd" % r)
		t.ok(script != null, "Sala %s compila" % r)
		var inst: RoomBase = script.new()
		inst.room_id = r
		var rows := inst.layout()
		t.ok(rows.size() >= 17, "%s tiene al menos 17 filas" % r)
		t.ok(rows[0].length() >= 30, "%s tiene al menos 30 columnas" % r)
		inst.free()
