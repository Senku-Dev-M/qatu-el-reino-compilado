extends RefCounted
## Vestimentas: contenido y retratos, regla de desbloqueo (la de la zona N pide
## vencer al jefe de la zona N-1), guardado y cambio de aspecto del Aprendiz.

var t

const JEFES := ["monolito", "espagueti", "nodo_huerfano", "guardian_parcial", "callback_hell",
	"scroll_infinito", "impostor_implicito", "kubernetes", "regresion"]


func test_contenido_y_retratos() -> void:
	var list := ContentDB.vestimentas_ordenadas()
	t.eq(list.size(), 11, "11 vestimentas (base + zonas 1 a 10)")
	t.eq(str(list[0].id), "base", "la base va primero")
	for v: Dictionary in list:
		for k in ["nombre", "descripcion", "zona", "requiere_jefe", "retrato", "capa", "borde", "franja_a", "franja_b", "espada"]:
			t.ok(v.has(k), "%s tiene %s" % [v.id, k])
		t.ok(VestimentasView.portrait(str(v.id)) != null, "%s: retrato cargado" % v.id)
		var jefe := str(v.requiere_jefe)
		if jefe != "":
			t.ok(not ContentDB.enemy(jefe).is_empty(), "%s: el jefe %s existe en el bestiario" % [v.id, jefe])


func test_regla_de_desbloqueo() -> void:
	GameState.new_game()
	t.ok(GameState.is_skin_unlocked("base"), "la base está libre")
	t.ok(GameState.is_skin_unlocked("z1_ruinas"), "la de la zona 1 está libre")
	for v: Dictionary in ContentDB.vestimentas_ordenadas():
		var zona := int(v.zona)
		if zona >= 2:
			t.ok(not GameState.is_skin_unlocked(str(v.id)), "%s bloqueada al empezar" % v.id)
			t.eq(str(v.requiere_jefe), JEFES[zona - 2], "%s: la desbloquea el jefe de la zona %d" % [v.id, zona - 1])
	t.ok(not GameState.set_skin("z2_torres"), "no se puede vestir una bloqueada")
	GameState.set_flag("jefe:monolito")
	t.ok(GameState.is_skin_unlocked("z2_torres"), "vencer al Monolito desbloquea la de la zona 2")
	t.ok(not GameState.is_skin_unlocked("z3_bosque"), "la de la zona 3 sigue bloqueada")
	t.eq(GameState.skins_unlocked_by("monolito").size(), 1, "el Monolito desbloquea una vestimenta")


func test_guardar_y_aspecto() -> void:
	GameState.new_game()
	GameState.set_flag("jefe:regresion")
	t.ok(GameState.set_skin("z10_arquitecto"), "vestir la del Gran Arquitecto")
	var saved := GameState.to_dict()
	GameState.new_game()
	GameState.from_dict(saved)
	t.eq(GameState.data.vestimenta, "z10_arquitecto", "la vestimenta se guarda")
	var tampered := saved.duplicate(true)
	tampered.flags.erase("jefe:regresion")
	GameState.from_dict(tampered)
	t.eq(GameState.data.vestimenta, "base", "si ya no está desbloqueada vuelve a la base")
	GameState.from_dict({"version": 2})
	t.eq(GameState.data.vestimenta, "base", "partidas antiguas empiezan con la base")
	var rig := PlayerRig.new()
	t.add_child(rig)
	var base_col := rig.cloak_col
	GameState.set_flag("jefe:monolito")
	GameState.set_skin("z2_torres")
	t.ok(rig.cloak_col != base_col and rig.detail == "anillos", "el Aprendiz cambia de colores y detalle al vestirse")
	var v := ContentDB.vestimenta("z2_torres")
	var e: Array = v.espada
	t.eq(rig.sword_col, Color(float(e[0]), float(e[1]), float(e[2])), "el Cursor toma el color de la vestimenta")
	rig.play_slash(Vector2.RIGHT, ContentDB.arma("cursor"))
	t.eq(rig.slash_col, rig.sword_col, "el tajo del Cursor usa ese color")
	rig.play_slash(Vector2.RIGHT, ContentDB.arma("lanza_rest"))
	t.ok(rig.slash_col != rig.sword_col, "las demás armas mantienen su color")
	rig.queue_free()
