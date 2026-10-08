extends Node2D
## Objeto recogible: fragmento de máscara, amuleto, mapa, arma o habilidad (santuario).

var room: RoomBase
var def: Dictionary
var kind := "shard"
var t := 0.0
var taken := false
var light: PointLight2D


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	kind = str(def.get("kind", "shard"))
	if kind == "fragment":
		kind = "shard"
	elif kind == "amulet" or kind == "amuleto":
		kind = "charm"
	
	taken = bool(GameState.get_flag(room.flag_key(def.id)))
	var val: String = str(def.get("value", def.get("ability", def.get("amulet", def.get("amuleto", "")))))
	if kind == "ability" and GameState.has_ability(val):
		taken = true
	if kind == "weapon" and GameState.has_weapon(val):
		taken = true
	var it := Interactable.new()
	add_child(it)
	var prompt: String = {"shard": "Recoger", "charm": "Recoger", "map": "Recoger el mapa", "weapon": "Tomar el arma", "ability": "Tocar el nodo"}.get(kind, "Recoger")
	it.setup(Vector2(140, 160), Vector2(0, -80), prompt)
	light = FX.make_light(Color(0.9, 0.95, 1.0) if kind != "ability" else Color(0.4, 1.0, 0.95), 3.5 if kind == "ability" else 2.2, 1.0)
	light.position = Vector2(0, -80)
	add_child(light)


func can_interact() -> bool:
	return not taken


func interact(_p: Player) -> void:
	if taken or RoomRouter.world == null:
		return
	taken = true
	GameState.set_flag(room.flag_key(def.id))
	var ui: GameUI = RoomRouter.world.ui
	FX.burst(get_parent(), global_position + Vector2(0, -80), Color(2.4, 2.4, 2.4), 30, 500.0, 0.8, 0.4, Vector2.ZERO)
	Events.camera_shake.emit(6.0, 0.4)
	var val: String = str(def.get("value", def.get("ability", def.get("amulet", def.get("amuleto", "")))))
	match kind:
		"shard":
			await ui.show_banner("Fragmento de máscara", "Fragmento de máscara", "Reúne dos fragmentos para forjar una máscara nueva y aumentar tu vida máxima.")
			GameState.add_shard()
		"charm":
			var a := ContentDB.amuleto(val)
			GameState.grant_charm(val)
			await ui.show_banner("Amuleto", a.get("nombre", "?"), "%s\nCoste: %d ranura(s). Equípalo desde el Códice sentado en un banco." % [a.get("efecto", ""), int(a.get("coste", 1))], a.get("leccion", ""))
		"map":
			await ui.show_banner("Objeto", "Mapa de la zona", "Consulta las salas que has visitado manteniendo {map}.")
		"weapon":
			var w := ContentDB.arma(val)
			GameState.grant_weapon(val)
			await ui.show_banner("Nueva arma", str(w.get("nombre", "?")), "%s
Daño %d · %s" % [str(w.get("descripcion", "")), int(w.get("dano", 1)), str(w.get("especial", ""))], str(w.get("leccion", "")), "Equipada. Pulsa [%s] para cambiar de arma o elígela en el Códice ([%s] > Armas)." % [Settings.key_name("arma"), Settings.key_name("codice")])
		"ability":
			if def.has("dialogo") or def.has("dialog"):
				await ui.dialog_id(str(def.get("dialogo", def.get("dialog", ""))))
			var hab := ContentDB.habilidad(val)
			GameState.grant_ability(val)
			await ui.show_banner("Nueva habilidad", hab.get("nombre", "?"), hab.get("descripcion", ""), hab.get("leccion", ""), str(hab.get("instruccion", "Pulsa [%s] cerca de un nodo brillante")) % Settings.key_name(str(hab.get("control", "grapple"))))
	RoomRouter.world.autosave()


func _process(delta: float) -> void:
	t += delta
	if taken:
		light.energy = move_toward(light.energy, 0.15 if kind == "ability" else 0.0, delta)
	queue_redraw()


func _draw() -> void:
	var bob := sin(t * 2.0) * 6.0
	var c := Vector2(0, -80 + bob)
	match kind:
		"ability":
			var stone := Color(0.05, 0.08, 0.08)
			draw_colored_polygon(PackedVector2Array([Vector2(-80, 0), Vector2(80, 0), Vector2(50, -30), Vector2(-50, -30)]), stone)
			for i in 5:
				var a := PI + PI * i / 4.0
				draw_line(Vector2(0, -30), Vector2(cos(a) * 90, -30 + sin(a) * 60 - 20), Color(0.08, 0.14, 0.14), 6.0, true)
			if not taken:
				for i in 6:
					var a := t * 1.5 + TAU * i / 6.0
					draw_line(c, c + Vector2(cos(a), sin(a)) * (60 + sin(t * 3 + i) * 10), Color(0.5, 2.2, 2.0, 0.4), 2.0, true)
				draw_circle(c, 34, Color(0.5, 2.0, 1.9, 0.12))
				draw_circle(c, 18, Color(1.0, 2.8, 2.6))
			else:
				draw_circle(Vector2(0, -80), 14, Color(0.2, 0.5, 0.5))
		"charm":
			if taken:
				return
			draw_circle(c, 30, Color(2.0, 1.6, 0.8, 0.1))
			var pts := PackedVector2Array()
			for i in 6:
				var a := TAU * i / 6.0 + t
				pts.append(c + Vector2(cos(a), sin(a)) * 16)
			draw_colored_polygon(pts, Color(2.2, 1.8, 0.9))
			draw_circle(c, 6, Color(0.1, 0.05, 0.02))
		"weapon":
			if taken:
				return
			var arr: Array = ContentDB.arma(str(def.get("value", ""))).get("color", [2.4, 2.4, 2.6])
			var wc := Color(float(arr[0]), float(arr[1]), float(arr[2]))
			draw_circle(c, 40, Color(wc, 0.12))
			for i in 4:
				var a := t * 1.2 + TAU * i / 4.0
				draw_line(c + Vector2(cos(a), sin(a)) * 30, c + Vector2(cos(a), sin(a)) * 44, Color(wc, 0.5), 2.0)
			draw_set_transform(c, sin(t * 1.5) * 0.25 - 0.6, Vector2.ONE)
			draw_line(Vector2(0, 26), Vector2(0, -30), wc, 5.0)
			draw_line(Vector2(-12, 12), Vector2(12, 12), Color(0.8, 0.7, 0.5), 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -42), Vector2(-7, -28), Vector2(7, -28)]), wc)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"map":
			if taken:
				return
			draw_circle(c, 34, Color(2.0, 1.6, 0.8, 0.1))
			draw_rect(Rect2(c + Vector2(-22, -14), Vector2(44, 28)), Color(0.9, 0.8, 0.6))
			draw_line(c + Vector2(-14, -4), c + Vector2(0, 6), Color(0.6, 0.2, 0.15), 2.0)
			draw_line(c + Vector2(0, 6), c + Vector2(14, -6), Color(0.6, 0.2, 0.15), 2.0)
			draw_circle(c + Vector2(-26, 0), 6, Color(0.7, 0.55, 0.35))
			draw_circle(c + Vector2(26, 0), 6, Color(0.7, 0.55, 0.35))
		_:
			if taken:
				return
			draw_circle(c, 30, Color(2.0, 2.0, 2.2, 0.1))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -10), c + Vector2(0, -18), c + Vector2(10, 6), c + Vector2(-4, 16)]), Color(2.4, 2.4, 2.5))
			draw_polyline(PackedVector2Array([c + Vector2(-6, -14), c + Vector2(-14, -24)]), Color(2.4, 2.4, 2.5), 3.0)
