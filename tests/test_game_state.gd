extends RefCounted

var t
var gs


func before_each() -> void:
	gs = load("res://autoload/game_state.gd").new()
	gs.new_game()


func after_each() -> void:
	gs.free()


func test_new_game_defaults() -> void:
	t.eq(gs.data.masks, 5, "máscaras iniciales")
	t.eq(gs.data.masks_max, 5, "máscaras máximas")
	t.eq(gs.data.bits, 0, "bits iniciales")
	t.eq(gs.data.room, "hub_plaza", "sala inicial")


func test_spend_bits_requires_funds() -> void:
	gs.add_bits(50)
	t.ok(not gs.spend_bits(60), "no alcanza")
	t.eq(gs.data.bits, 50, "no se descuenta")
	t.ok(gs.spend_bits(40), "sí alcanza")
	t.eq(gs.data.bits, 10, "se descuenta")


func test_damage_and_death() -> void:
	t.ok(not gs.damage(4), "sobrevive con 1")
	t.eq(gs.data.masks, 1, "queda 1")
	t.ok(gs.damage(2), "muere")
	t.eq(gs.data.masks, 0, "no baja de 0")


func test_heal_capped() -> void:
	gs.damage(2)
	gs.heal(5)
	t.eq(gs.data.masks, 5, "no supera el máximo")


func test_heal_energy() -> void:
	t.ok(not gs.try_consume_heal(), "sin energía no cura")
	gs.add_energy(0.5)
	t.ok(gs.try_consume_heal(), "con energía cura")
	t.ok(absf(gs.data.energy - 0.17) < 0.001, "consume 0.33")
	gs.add_energy(5.0)
	t.eq(gs.data.energy, 1.0, "energía tope 1")


func test_shards_grant_mask() -> void:
	gs.damage(3)
	gs.add_shard()
	t.eq(gs.data.masks_max, 5, "un fragmento no basta")
	gs.add_shard()
	t.eq(gs.data.masks_max, 6, "dos fragmentos dan máscara")
	t.eq(gs.data.masks, 6, "y restauran vida")
	t.eq(gs.data.mask_shards, 0, "fragmentos se consumen")


func test_death_creates_shade_and_recover() -> void:
	gs.add_bits(120)
	gs.on_death("z3_claro", Vector2(100, 200))
	t.eq(gs.data.bits, 0, "pierde bits")
	t.eq(gs.data.shade.bits, 120, "sombra guarda bits")
	t.eq(gs.data.shade.room, "z3_claro", "sala de la sombra")
	t.eq(gs.data.masks, gs.data.masks_max, "reaparece con vida")
	gs.recover_shade()
	t.eq(gs.data.bits, 120, "recupera bits")
	t.eq(gs.data.shade, null, "sombra desaparece")


func test_second_death_loses_shade() -> void:
	gs.add_bits(80)
	gs.on_death("z3_raiz", Vector2.ZERO)
	gs.add_bits(10)
	gs.on_death("z3_copa", Vector2.ONE)
	t.eq(gs.data.shade.bits, 10, "la sombra antigua se pierde")
	t.eq(gs.data.shade.room, "z3_copa", "nueva sombra")


func test_death_without_bits_leaves_no_shade() -> void:
	gs.on_death("z3_raiz", Vector2.ZERO)
	t.eq(gs.data.shade, null, "sin bits no hay sombra")


func test_tablillas_and_semantica_charm() -> void:
	t.ok(gs.read_tablilla("L01"), "nueva")
	t.ok(not gs.read_tablilla("L01"), "repetida")
	for i in range(2, 7):
		gs.read_tablilla("L0%d" % i)
	t.ok("semantica" in gs.data.charms_owned, "6 lecciones otorgan Semántica")


func test_charm_slots() -> void:
	gs.grant_charm("box_model")
	gs.grant_charm("delegacion")
	gs.grant_charm("semantica")
	t.ok(gs.equip_charm("delegacion", 2), "equipa coste 2")
	t.ok(gs.equip_charm("box_model", 1), "equipa coste 1")
	t.ok(not gs.equip_charm("semantica", 1), "sin ranuras")
	gs.unequip_charm("box_model")
	t.ok(gs.equip_charm("semantica", 1), "tras liberar sí")
	t.ok(not gs.equip_charm("no_existe", 1), "no poseído")


func test_register_kill_counts() -> void:
	t.eq(gs.register_kill("nodo_zombi"), 1, "primera")
	t.eq(gs.register_kill("nodo_zombi"), 2, "segunda")


func test_flags_and_rest() -> void:
	gs.set_flag("z3_copa:atajo")
	t.ok(gs.get_flag("z3_copa:atajo"), "flag activa")
	t.ok(not gs.get_flag("otra"), "flag ausente es false")
	gs.damage(3)
	gs.rest("z3_tronco", "banco")
	t.eq(gs.data.masks, 5, "banco cura")
	t.eq(gs.data.bench_room, "z3_tronco", "banco guardado")


func test_roundtrip_dict() -> void:
	gs.add_bits(33)
	gs.grant_ability("event_listener")
	gs.set_flag("x")
	var d: Dictionary = gs.to_dict()
	var gs2 = load("res://autoload/game_state.gd").new()
	gs2.from_dict(JSON.parse_string(JSON.stringify(d)))
	t.eq(gs2.data.bits, 33, "bits")
	t.ok(gs2.has_ability("event_listener"), "habilidad")
	t.ok(gs2.get_flag("x"), "flag")
	t.eq(typeof(gs2.data.masks), TYPE_INT, "enteros restaurados como int")
	gs2.free()


func test_completion_percent() -> void:
	var before: float = gs.zone_completion(3)
	gs.read_tablilla("L01")
	t.ok(gs.zone_completion(3) > before, "leer sube el porcentaje")


func test_complete_lesson_and_terms() -> void:
	t.ok(gs.complete_lesson("L03"), "primera comprobación")
	t.eq(gs.data.bits, gs.LESSON_CHECK_BITS, "da Bits")
	t.ok(not gs.complete_lesson("L03"), "no se repite")
	t.eq(gs.data.bits, gs.LESSON_CHECK_BITS, "no duplica Bits")
	t.eq(gs.learn_terms(["etiqueta", "elemento"]), ["etiqueta", "elemento"], "términos nuevos")
	t.eq(gs.learn_terms(["etiqueta", "atributo"]), ["atributo"], "solo los nuevos")


func test_migrates_v1_save() -> void:
	gs.from_dict({"version": 1, "tablillas": ["T01", "T02"], "bits": 10})
	t.eq(gs.data.tablillas, [], "tablillas antiguas descartadas")
	t.eq(gs.data.version, gs.SAVE_VERSION, "versión actualizada")
	t.eq(gs.data.bits, 10, "resto de datos conservado")