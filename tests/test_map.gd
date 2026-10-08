extends RefCounted
## Mapa: cada zona tiene un mapa que se puede conseguir y activa la vista, las
## salas de una zona no se solapan en el mapa y el terreno de cada sala se dibuja.

var t


func test_cada_zona_tiene_su_mapa_y_se_activa() -> void:
	for zone in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		GameState.new_game()
		var src := MapView.map_source(zone)
		t.ok(not src.is_empty(), "zona %d: hay un mapa que conseguir" % zone)
		if src.is_empty():
			continue
		t.ok(not MapView.zone_has_map(zone), "zona %d: sin recogerlo no hay mapa" % zone)
		GameState.set_flag(str(src.flag))
		t.ok(MapView.zone_has_map(zone), "zona %d: al recogerlo se activa (%s)" % [zone, src.flag])
	t.ok(MapView.zone_has_map(0), "la Plaza siempre tiene mapa")


func test_el_mapa_de_la_tienda_y_el_objeto_usan_la_misma_bandera() -> void:
	# El objeto «mapa» guarda la bandera <sala>:<id>; la vista debe leer esa misma.
	for id: String in WorldMap.ROOMS.keys():
		for d: Dictionary in WorldMap.info(id).get("defs", []):
			if d.get("type") == "pickup" and d.get("kind") == "map":
				var src := MapView.map_source(int(WorldMap.ROOMS[id].zone))
				t.eq(str(src.get("flag", "")), "%s:%s" % [id, d.id], "%s: bandera del mapa" % id)


func test_las_salas_no_se_solapan_en_el_mapa() -> void:
	var ids: Array = WorldMap.ROOMS.keys()
	var fallos := []
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: String = ids[i]
			var b: String = ids[j]
			if int(WorldMap.ROOMS[a].zone) != int(WorldMap.ROOMS[b].zone):
				continue
			if WorldMap.rect(a).intersects(WorldMap.rect(b)):
				fallos.append("%s/%s" % [a, b])
	t.ok(fallos.is_empty(), "sin salas solapadas (%s)" % ", ".join(fallos))


func test_las_puertas_laterales_quedan_enfrentadas() -> void:
	# Dos salas unidas por puertas izquierda/derecha: misma fila y pasillo corto.
	var fallos := []
	for id: String in WorldMap.ROOMS.keys():
		var r := WorldMap.rect(id)
		for d: Dictionary in WorldMap.info(id).get("doors", []):
			var to := str(d.get("to", ""))
			var cell: Vector2i = d.cell
			if d.get("type") != "door" or not WorldMap.ROOMS.has(to) or cell.x != int(r.size.x) - 1:
				continue
			if int(WorldMap.ROOMS[to].zone) != int(WorldMap.ROOMS[id].zone):
				continue
			for d2: Dictionary in WorldMap.info(to).get("doors", []):
				var c2: Vector2i = d2.cell
				if str(d2.get("to", "")) == id and str(d2.get("id", "")) == str(d.get("to_door", "")) and c2.x == 0:
					var r2 := WorldMap.rect(to)
					var gap := r2.position.x - r.end.x
					if gap > 20:
						continue  # atajo a una sala lejana (Raíz → Copa): no es vecina en el mapa
					var dy := (r2.position.y + c2.y) - (r.position.y + cell.y)
					if gap < 0 or gap > 6 or absi(int(dy)) > 0:
						fallos.append("%s→%s (hueco %d, desnivel %d)" % [id, to, gap, dy])
	t.ok(fallos.is_empty(), "puertas enfrentadas en el mapa (%s)" % ", ".join(fallos))


func test_el_terreno_de_cada_sala_se_dibuja() -> void:
	for id: String in WorldMap.ROOMS.keys():
		var tex := MapView.terrain_texture(id)
		t.ok(tex != null and tex.get_width() == int(WorldMap.rect(id).size.x), "%s: textura del terreno" % id)
