class_name Codice
extends Modal
## Inventario educativo: Lecciones, Glosario, Bestiario, Amuletos, Armas y Progreso.

signal open_tablilla(id: String)

var tabs: TabContainer
var tab_lists := {}
var details := {}
var slots_label: Label
var foot: Label


func _ready() -> void:
	dim.color = Color(0, 0, 0, 0.85)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 110
	root.offset_right = -110
	root.offset_top = 60
	root.offset_bottom = -50
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var title := UITheme.label("Códice", 60, UITheme.GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	root.add_child(UITheme.ornament(640))
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.tab_changed.connect(func(_i): _focus_tab())
	root.add_child(tabs)
	for tab_name in ["Lecciones", "Glosario", "Bestiario", "Amuletos", "Armas", "Progreso"]:
		_make_tab(tab_name)
	foot = UITheme.label("", 22, UITheme.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(foot)


func _make_tab(tab_name: String) -> void:
	var hb := HBoxContainer.new()
	hb.name = tab_name
	hb.add_theme_constant_override("separation", 34)
	tabs.add_child(hb)
	if tab_name == "Progreso":
		var lbl := UITheme.label("", 34)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lbl)
		details[tab_name] = lbl
		return
	var list := ItemList.new()
	list.custom_minimum_size = Vector2(620, 0)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(func(i): _on_select(tab_name, i))
	list.item_activated.connect(func(i): _on_activate(tab_name, i))
	hb.add_child(list)
	tab_lists[tab_name] = list
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UITheme.panel_style(0.6))
	hb.add_child(panel)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 14)
	panel.add_child(detail)
	details[tab_name] = detail


func open() -> void:
	open_modal()
	_refresh_all()
	_focus_tab()


func _focus_tab() -> void:
	if foot == null or tabs.get_current_tab_control() == null:
		return
	var name := tabs.get_current_tab_control().name
	var list: ItemList = tab_lists.get(name)
	if list and list.item_count > 0:
		list.grab_focus()
		var sel := list.get_selected_items()
		var idx := sel[0] if sel.size() > 0 else _first_selectable(list)
		list.select(idx)
		_on_select(name, idx)
	var extra := ""
	match name:
		"Amuletos": extra = "    [%s] Equipar / quitar" % Settings.key_name("jump")
		"Armas": extra = "    [%s] Equipar" % Settings.key_name("jump")
		"Lecciones": extra = "    [%s] Estudiar la lección" % Settings.key_name("jump")
	foot.text = "[Q] / [E] Cambiar pestaña    [%s] Cerrar%s" % [Settings.key_name("attack"), extra]


func _first_selectable(list: ItemList) -> int:
	for i in list.item_count:
		if list.is_item_selectable(i):
			return i
	return 0


func _refresh_all() -> void:
	_fill_lecciones()
	_fill_glosario()
	_fill_bestiario()
	_fill_amuletos()
	_fill_armas()
	_fill_progreso()


func _fill_lecciones() -> void:
	var list: ItemList = tab_lists.Lecciones
	list.clear()
	for z in ContentDB.zonas_ordenadas():
		var zh := list.add_item("SEMANA %d · %s" % [int(z.semana), str(z.nombre).to_upper()])
		list.set_item_selectable(zh, false)
		list.set_item_metadata(zh, "")
		list.set_item_custom_fg_color(zh, UITheme.GOLD)
		for sala in z.salas:
			var lessons := ContentDB.lecciones_de_sala(sala)
			if lessons.is_empty():
				continue
			var h := list.add_item("   — %s —" % ContentDB.nombre_sala(sala).to_upper())
			list.set_item_selectable(h, false)
			list.set_item_metadata(h, "")
			list.set_item_custom_fg_color(h, UITheme.CYAN)
			for l in lessons:
				var known: bool = l.id in GameState.data.tablillas
				var mark := "★" if GameState.is_lesson_checked(l.id) else ("✓" if known else "○")
				var i := list.add_item(("     %s  %s" % [mark, l.titulo]) if known else "     ○  ???")
				list.set_item_metadata(i, l.id)
				if not known:
					list.set_item_custom_fg_color(i, UITheme.DIM)
				elif GameState.is_lesson_checked(l.id):
					list.set_item_custom_fg_color(i, UITheme.GOLD)


func _fill_glosario() -> void:
	var list: ItemList = tab_lists.Glosario
	list.clear()
	for g in ContentDB.glosario_ordenado():
		if g.id in GameState.data.glosario:
			var i := list.add_item(g.termino)
			list.set_item_metadata(i, g.id)
	if list.item_count == 0:
		var i := list.add_item("Aún no hay términos")
		list.set_item_metadata(i, "")
		list.set_item_selectable(i, false)
		list.set_item_custom_fg_color(i, UITheme.DIM)


func _fill_bestiario() -> void:
	var list: ItemList = tab_lists.Bestiario
	list.clear()
	for e in ContentDB.all_bestiary():
		var k := GameState.kills(e.id)
		var i := list.add_item(e.nombre if k > 0 else "???")
		list.set_item_metadata(i, e.id)
		if k == 0:
			list.set_item_custom_fg_color(i, UITheme.DIM)
		elif k >= int(e.derrotas_requeridas):
			list.set_item_custom_fg_color(i, UITheme.GOLD)


func _fill_amuletos() -> void:
	var list: ItemList = tab_lists.Amuletos
	list.clear()
	var all_charms := []
	for z in ContentDB.zonas_ordenadas():
		all_charms.append_array(ContentDB.amuletos_de_zona(int(z.zona)))
	for a in all_charms:
		var owned: bool = a.id in GameState.data.charms_owned
		var equipped := GameState.is_charm_equipped(a.id)
		var label: String = "???"
		if owned:
			label = "%s%s  %s" % ["◆ " if equipped else "◇ ", a.nombre, "●".repeat(int(a.coste))]
		var i := list.add_item(label)
		list.set_item_metadata(i, a.id)
		if not owned:
			list.set_item_custom_fg_color(i, UITheme.DIM)
		elif equipped:
			list.set_item_custom_fg_color(i, UITheme.GOLD)


func _fill_armas() -> void:
	var list: ItemList = tab_lists.Armas
	list.clear()
	for w in ContentDB.armas_ordenadas():
		var owned := GameState.has_weapon(str(w.id))
		var equipped: bool = owned and GameState.data.arma == w.id
		var label := "???"
		if owned:
			label = "%s%s" % ["⚔ " if equipped else "   ", w.nombre]
		var i := list.add_item(label)
		list.set_item_metadata(i, w.id)
		if not owned:
			list.set_item_custom_fg_color(i, UITheme.DIM)
		elif equipped:
			list.set_item_custom_fg_color(i, UITheme.GOLD)


func _stat_bar(value: float, max_value: float) -> String:
	var n := clampi(roundi(value / max_value * 5.0), 1, 5)
	return "■".repeat(n) + "□".repeat(5 - n)


func _fill_progreso() -> void:
	var d: Dictionary = GameState.data
	var secs := int(d.play_time)
	var lines := []
	for z in ContentDB.zonas_ordenadas():
		var zone := int(z.zona)
		var read := 0
		var checked := 0
		var lessons := ContentDB.lecciones_de_zona(zone)
		for tab in lessons:
			if tab.id in d.tablillas:
				read += 1
			if tab.id in d.lecciones_ok:
				checked += 1
		var sellos_done := 0
		for s in ContentDB.sellos_de_zona(zone):
			if s.id in d.sellos:
				sellos_done += 1
		lines.append("SEMANA %d · %s — %d %%" % [int(z.semana), str(z.nombre).to_upper(), roundi(GameState.zone_completion(zone))])
		lines.append("   Lecciones: %d / %d estudiadas · %d comprobadas   ·   Sellos: %d / %d" % [read, lessons.size(), checked, sellos_done, ContentDB.sellos_de_zona(zone).size()])
	lines.append_array([
		"",
		"Términos del glosario: %d / %d" % [d.glosario.size(), ContentDB.tables.glosario.size()],
		"Amuletos: %d   ·   Máscaras: %d   ·   Fragmentos: %d / 2" % [d.charms_owned.size(), d.masks_max, d.mask_shards],
		"Habilidades: %s" % (", ".join(d.abilities.map(func(a): return ContentDB.habilidad(a).get("nombre", a))) if not d.abilities.is_empty() else "ninguna"),
		"Tiempo de juego: %d:%02d:%02d" % [secs / 3600, (secs / 60) % 60, secs % 60],
	])
	(details.Progreso as Label).text = "\n".join(lines)


func _clear_detail(tab_name: String) -> VBoxContainer:
	var box: VBoxContainer = details[tab_name]
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	return box


func _add_text(box: VBoxContainer, text: String, size := 30, color := UITheme.TEXT, title := false) -> Label:
	var l := UITheme.label(text, size, color, title)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(700, 0)
	box.add_child(l)
	return l


func _on_select(tab_name: String, index: int) -> void:
	var list: ItemList = tab_lists[tab_name]
	if index < 0 or index >= list.item_count:
		return
	var id: String = str(list.get_item_metadata(index))
	var box := _clear_detail(tab_name)
	if id == "":
		return
	AudioManager.play_sfx("ui_move")
	match tab_name:
		"Lecciones":
			var l := ContentDB.leccion(id)
			var pos := ContentDB.posicion_en_sala(id)
			_add_text(box, "%s · LECCIÓN %d DE %d · NIVEL %s" % [ContentDB.nombre_sala(l.sala).to_upper(), pos.x, pos.y, str(l.nivel).to_upper()], 22, UITheme.DIM, true)
			if id in GameState.data.tablillas:
				_add_text(box, l.titulo, 44, UITheme.GOLD, true)
				box.add_child(RichFormat.text_label(RichFormat.lesson_text(str(l.resumen)), 30))
				var status := "★ Comprobada" if GameState.is_lesson_checked(id) else "✓ Estudiada — falta responder la comprobación"
				_add_text(box, status, 26, UITheme.GOLD if GameState.is_lesson_checked(id) else UITheme.CYAN, true)
				_add_text(box, "%d páginas · Pulsa [%s] para abrirla" % [l.paginas.size(), Settings.key_name("jump")], 24, UITheme.DIM)
			else:
				_add_text(box, "Lección sin descubrir", 40, UITheme.DIM, true)
				_add_text(box, "Búscala en: %s" % ContentDB.nombre_sala(l.sala), 28, UITheme.DIM)
		"Glosario":
			var g := ContentDB.termino(id)
			_add_text(box, g.termino, 44, UITheme.GOLD, true)
			box.add_child(RichFormat.text_label(RichFormat.lesson_text(str(g.definicion)), 30))
			if str(g.get("ejemplo", "")) != "":
				box.add_child(RichFormat.code_panel(str(g.ejemplo), str(g.get("lenguaje", "html")), -1, 22))
			_add_text(box, "Se explica en: %s" % ContentDB.leccion(g.leccion).get("titulo", g.leccion), 24, UITheme.DIM)
		"Bestiario":
			var e := ContentDB.enemy(id)
			var k := GameState.kills(id)
			var need := int(e.derrotas_requeridas)
			if k == 0:
				_add_text(box, "???", 44, UITheme.DIM, true)
				_add_text(box, "Aún no te has cruzado con este bug.", 28, UITheme.DIM)
				return
			_add_text(box, e.nombre, 44, UITheme.GOLD, true)
			_add_text(box, "Derrotados: %d / %d" % [mini(k, need), need], 24, UITheme.DIM, true)
			_add_text(box, e.descripcion, 30)
			if k >= need:
				box.add_child(UITheme.ornament(400, UITheme.CYAN))
				_add_text(box, "Lección", 26, UITheme.CYAN, true)
				_add_text(box, e.leccion, 30, UITheme.CYAN)
			else:
				_add_text(box, "Derrota %d más para descifrar su lección." % (need - k), 26, UITheme.DIM)
		"Amuletos":
			var a := ContentDB.amuleto(id)
			slots_label = _add_text(box, "Ranuras de memoria: %s" % _slots_text(), 26, UITheme.DIM, true)
			if not (id in GameState.data.charms_owned):
				_add_text(box, "???", 44, UITheme.DIM, true)
				return
			_add_text(box, a.nombre, 44, UITheme.GOLD, true)
			_add_text(box, "Coste: %d ranura(s)" % int(a.coste), 24, UITheme.DIM, true)
			_add_text(box, a.efecto, 30)
			_add_text(box, a.leccion, 28, UITheme.CYAN)
			if not GameState.at_bench:
				_add_text(box, "Solo puedes cambiar amuletos sentado en un banco.", 24, UITheme.DIM)
		"Armas":
			var w := ContentDB.arma(id)
			if not GameState.has_weapon(id):
				_add_text(box, "???", 44, UITheme.DIM, true)
				var z := int(w.get("zona", 0))
				_add_text(box, "Se encuentra en: %s" % str(ContentDB.zona(z).get("nombre", "Qatu")), 28, UITheme.DIM)
				return
			_add_text(box, w.nombre, 44, UITheme.GOLD, true)
			var speed := 1.0 / maxf(float(w.cadencia), 0.1)
			_add_text(box, "Daño      %s  %d" % [_stat_bar(float(w.dano), 3.0), int(w.dano)], 26, UITheme.TEXT, true)
			_add_text(box, "Alcance   %s" % _stat_bar(float(w.alcance), 2.0), 26, UITheme.TEXT, true)
			_add_text(box, "Velocidad %s" % _stat_bar(speed, 1.8), 26, UITheme.TEXT, true)
			_add_text(box, str(w.especial), 28, UITheme.CYAN)
			_add_text(box, str(w.descripcion), 28)
			box.add_child(UITheme.ornament(400, UITheme.CYAN))
			_add_text(box, str(w.leccion), 26, UITheme.CYAN)
			if GameState.data.arma == id:
				_add_text(box, "Equipada · [%s] cambia de arma durante el juego" % Settings.key_name("arma"), 24, UITheme.GOLD)


func _slots_text() -> String:
	var free := GameState.free_slots()
	return "●".repeat(GameState.CHARM_SLOTS - free) + "○".repeat(free)


func _on_activate(tab_name: String, index: int) -> void:
	var list: ItemList = tab_lists[tab_name]
	var id: String = str(list.get_item_metadata(index))
	if id == "":
		return
	match tab_name:
		"Lecciones":
			if id in GameState.data.tablillas:
				open_tablilla.emit(id)
		"Armas":
			if GameState.equip_weapon(id):
				AudioManager.play_sfx("charm_on")
				_fill_armas()
				list.select(index)
				_on_select(tab_name, index)
		"Amuletos":
			if not (id in GameState.data.charms_owned):
				return
			if not GameState.at_bench:
				AudioManager.play_sfx("sello_bad")
				return
			if GameState.is_charm_equipped(id):
				GameState.unequip_charm(id)
				AudioManager.play_sfx("charm_off")
			elif GameState.equip_charm(id, GameState.charm_cost(id)):
				AudioManager.play_sfx("charm_on")
			else:
				AudioManager.play_sfx("sello_bad")
			_fill_amuletos()
			list.select(index)
			_on_select(tab_name, index)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("tab_prev"):
		tabs.current_tab = wrapi(tabs.current_tab - 1, 0, tabs.get_tab_count())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("tab_next"):
		tabs.current_tab = wrapi(tabs.current_tab + 1, 0, tabs.get_tab_count())
		get_viewport().set_input_as_handled()
	elif cancel_pressed(event) or event.is_action_pressed("codice") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		close_modal()
