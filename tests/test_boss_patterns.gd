extends RefCounted
## Jefes: vida ajustada, daño por arma sin saltarse fases, escudo de la fase 2
## que se rompe con las runas correctas, y cada ataque propio se ejecuta,
## genera peligros y termina.

var t
var room: RoomBase
var boss: Node2D

const ARENAS := {
	"monolito": ["z1_arena", "jefe_monolito", 18],
	"espagueti": ["z2_arena", "jefe_espagueti", 18],
	"kubernetes": ["z8_arena", "jefe_kubernetes", 18],
	"regresion": ["z9_arena", "jefe_regresion", 18],
	"demo_final": ["hub_sanctum", "jefe_demo_final", 22],
}
const MY_BOSSES := {
	"nodo_huerfano": ["z3_arena", "burbujeo"],
	"guardian_parcial": ["z4_arena", "rejilla"],
	"callback_hell": ["z5_arena", "set_timeout"],
	"scroll_infinito": ["z6_arena", "carga_diferida"],
	"impostor_implicito": ["z7_arena", "phishing"],
}


func _setup(room_id: String, arena_id: String, half: int, kind: String) -> void:
	GameState.new_game()
	room = load("res://rooms/%s.gd" % room_id).new()
	room.room_id = room_id
	t.add_child(room)
	room.build()
	var arena: Node2D = room.get_entity(arena_id)
	boss = load("res://scripts/boss/%s.gd" % kind).new()
	boss.setup_arena(arena, arena.global_position.y, arena.global_position.x - half * 64, arena.global_position.x + half * 64)
	room.entity_layer.add_child(boss)
	boss.global_position = arena.global_position + Vector2(0, -300)
	var p := Player.new()
	room.add_child(p)
	p.global_position = arena.global_position + Vector2(-300, -4)
	p.invuln = 9999.0
	await t.get_tree().process_frame


func after_each() -> void:
	if is_instance_valid(room):
		room.queue_free()
	await t.get_tree().process_frame


func _hazards() -> int:
	var n := 0
	for c in room.entity_layer.get_children():
		if c is DamageArea or c is EnemyBase:
			n += 1
	return n


func test_jefes_con_menos_vida() -> void:
	var limits := {"monolito": 30, "espagueti": 30, "kubernetes": 30, "regresion": 32, "demo_final": 36,
		"nodo_huerfano": 24, "guardian_parcial": 26, "callback_hell": 28, "scroll_infinito": 28, "impostor_implicito": 30}
	for kind: String in limits:
		var script: GDScript = load("res://scripts/boss/%s.gd" % kind)
		var max_hp: int = script.get_script_constant_map().get("MAX_HP", 999)
		t.ok(max_hp <= int(limits[kind]), "%s: vida máxima %d (≤ %d)" % [kind, max_hp, limits[kind]])


func test_escudo_de_fase_2_se_rompe_con_las_runas() -> void:
	for kind: String in ARENAS:
		var a: Array = ARENAS[kind]
		await _setup(a[0], a[1], a[2], kind)
		var b := boss as BossBase
		b.invulnerable = false
		b.state = "idle"
		# Un golpe fuerte no se salta la fase 2.
		for i in 40:
			if b.phase >= 2:
				break
			b.take_hit({"damage": 3})
		t.eq(b.phase, 2, "%s: entra en fase 2" % kind)
		t.eq(b.hp, b.phase2_hp, "%s: el daño se detiene en el umbral" % kind)
		t.ok(b.shield, "%s: escudo en fase 2" % kind)
		t.ok(b.runes.size() >= 3, "%s: aparecen runas (%d)" % [kind, b.runes.size()])
		var hp0 := b.hp
		b.take_hit({"damage": 3})
		t.eq(b.hp, hp0, "%s: con escudo no recibe daño" % kind)
		var correct: Array = b.question().get("correct", [])
		var wrong: CodeRune = null
		for r in b.runes:
			if not (r.line in correct):
				wrong = r
		if wrong:
			wrong.take_hit({})
			t.ok(b.shield, "%s: una runa incorrecta no rompe el escudo" % kind)
		for r in b.runes.duplicate():
			if r.line in correct:
				r.take_hit({})
		t.ok(not b.shield, "%s: las runas correctas rompen el escudo" % kind)
		t.eq(b.state, "stunned", "%s: queda aturdido" % kind)
		b.take_hit({"damage": 1})
		t.eq(b.hp, hp0 - 2, "%s: aturdido recibe daño extra" % kind)
		await after_each()


func test_cada_ataque_propio_genera_peligros_y_termina() -> void:
	for kind: String in ARENAS:
		var a: Array = ARENAS[kind]
		await _setup(a[0], a[1], a[2], kind)
		var b := boss as BossBase
		var names := {}
		for ph in [1, 2, 3]:
			for n in b.attacks(ph):
				names[n] = true
		t.ok(names.size() >= 4, "%s: al menos 4 ataques distintos (%d)" % [kind, names.size()])
		for n: String in names.keys():
			b.phase = 3
			b.state = "busy"
			b.last_attack = n
			var before := _hazards()
			b.call("_atk_" + n)
			var most := before
			var finished := false
			for i in 900:
				await t.get_tree().physics_frame
				most = maxi(most, _hazards())
				if b.state == "idle":
					finished = true
					break
			t.ok(most > before, "%s/%s: genera peligros" % [kind, n])
			t.ok(finished, "%s/%s: termina y vuelve a idle" % [kind, n])
			for c in room.entity_layer.get_children():
				if c is DamageArea or c is EnemyBase:
					c.queue_free()
			await t.get_tree().physics_frame
		await after_each()


func test_ataques_patron_distintos_entre_jefes() -> void:
	var seen := {}
	var repeated := []
	for kind: String in ARENAS:
		var b: BossBase = load("res://scripts/boss/%s.gd" % kind).new()
		for n in b.attacks(3):
			if seen.has(n) and seen[n] != kind:
				repeated.append("%s (%s y %s)" % [n, seen[n], kind])
			seen[n] = kind
		b.free()
	t.ok(repeated.is_empty(), "cada jefe tiene sus propios ataques %s" % ", ".join(repeated))


func test_ataques_caracteristicos_de_las_zonas_3_a_7() -> void:
	for kind: String in MY_BOSSES:
		var a: Array = MY_BOSSES[kind]
		await _setup(a[0], "arena", 17, kind)
		boss.invulnerable = false
		var before := _hazards()
		boss.call("_special_" + str(a[1]))
		t.eq(boss.state, "special", "%s: estado del ataque especial" % kind)
		var most := before
		for i in 60:
			await t.get_tree().physics_frame
			most = maxi(most, _hazards())
		t.ok(most > before, "%s: %s genera peligros" % [kind, a[1]])
		var hp0: int = boss.hp
		boss.shield = false
		boss.take_hit({"damage": 50})
		t.ok(boss.hp == boss.PHASE2_HP and boss.hp < hp0, "%s: el daño del arma cuenta y no salta la fase" % kind)
		await after_each()
