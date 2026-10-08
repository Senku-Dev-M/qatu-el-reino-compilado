class_name GameUI
extends CanvasLayer
## Punto de acceso a toda la interfaz del juego. Las pantallas modales
## pausan el árbol mientras están abiertas.

var hud: HUD
var fade: Fade
var dialog_box: DialogBox
var tablilla_view: LeccionView
var sello_view: SelloView
var shop_view: ShopView
var banner: Banner
var codice: Codice
var map_view: MapView
var pause_menu: PauseMenu
var options: OptionsMenu
var vestimentas: VestimentasView
var notifications: VBoxContainer
var area_label: VBoxContainer
var boss_bar: Control
var boss_name := ""
var boss_ratio := 1.0
var boss_ratio_shown := 1.0

var _modal_count := 0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	add_child(root)

	hud = HUD.new()
	root.add_child(hud)

	notifications = VBoxContainer.new()
	notifications.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notifications.position = Vector2(-760, 60)
	notifications.custom_minimum_size = Vector2(700, 0)
	notifications.alignment = BoxContainer.ALIGNMENT_BEGIN
	notifications.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notifications)

	area_label = VBoxContainer.new()
	area_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	area_label.custom_minimum_size = Vector2(1200, 0)
	area_label.position = Vector2(-600, 200)
	area_label.modulate.a = 0.0
	area_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(area_label)

	boss_bar = Control.new()
	boss_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.visible = false
	boss_bar.draw.connect(_draw_boss_bar)
	root.add_child(boss_bar)

	map_view = MapView.new()
	root.add_child(map_view)

	for m in ["dialog_box", "sello_view", "shop_view", "codice", "tablilla_view", "banner", "pause_menu", "options", "vestimentas"]:
		var node: Modal
		match m:
			"dialog_box": node = DialogBox.new()
			"sello_view": node = SelloView.new()
			"shop_view": node = ShopView.new()
			"codice": node = Codice.new()
			"tablilla_view": node = LeccionView.new()
			"banner": node = Banner.new()
			"pause_menu": node = PauseMenu.new()
			"options": node = OptionsMenu.new()
			"vestimentas": node = VestimentasView.new()
		set(m, node)
		root.add_child(node)

	sello_view.reread_requested.connect(func(id): _queue_reread(id))
	codice.open_tablilla.connect(func(id):
		await show_tablilla(id, false)
		codice._refresh_all()
		codice._focus_tab())
	pause_menu.options_requested.connect(func():
		await _run(options, func(): options.open())
		pause_menu.first.grab_focus())
	pause_menu.skins_requested.connect(func():
		await _run(vestimentas, func(): vestimentas.open())
		pause_menu.first.grab_focus())
	pause_menu.quit_requested.connect(_quit_to_menu)

	fade = Fade.new()
	add_child(fade)

	Events.notify.connect(notify)
	Events.tablilla_read.connect(func(id, is_new):
		if is_new: notify("Nueva lección: " + str(ContentDB.leccion(id).get("titulo", id))))
	Events.enemy_defeated.connect(_on_enemy_defeated)
	Events.charm_granted.connect(_on_charm_granted)


func is_modal_open() -> bool:
	return _modal_count > 0


func _run(modal: Modal, opener: Callable) -> Variant:
	_modal_count += 1
	get_tree().paused = true
	Events.ui_opened.emit()
	opener.call()
	var result = await modal.closed
	_modal_count -= 1
	if _modal_count <= 0:
		_modal_count = 0
		get_tree().paused = false
		Events.ui_closed.emit()
	return result


# --- API --------------------------------------------------------------------------------

func dialog(lines: Array, speaker := "") -> void:
	await _run(dialog_box, func(): dialog_box.show_lines(lines, speaker))


func dialog_id(id: String) -> void:
	await dialog(ContentDB.dialogo(id), ContentDB.dialogo_speaker(id))


func show_tablilla(id: String, is_new: bool) -> void:
	var added := GameState.learn_terms(ContentDB.terminos_de_leccion(id))
	if not added.is_empty():
		notify("Glosario: %d término(s) nuevo(s)" % added.size())
	await _run(tablilla_view, func(): tablilla_view.show_leccion(id, is_new))


func sello(id: String) -> bool:
	var result = await _run(sello_view, func(): sello_view.show_sello(id))
	return result == true


func _queue_reread(id: String) -> void:
	await show_tablilla(id, false)


func shop(shop_id: String) -> void:
	await _run(shop_view, func(): shop_view.show_shop(shop_id))


func show_banner(kind: String, title: String, desc: String, lesson := "", control := "") -> void:
	await _run(banner, func(): banner.show_banner(kind, title, desc, lesson, control))


func open_codice() -> void:
	await _run(codice, func(): codice.open())


func open_pause() -> void:
	await _run(pause_menu, func(): pause_menu.open())


func show_map(open: bool) -> void:
	map_view.set_open(open)
	if RoomRouter.world and RoomRouter.world.player:
		var p: Player = RoomRouter.world.player
		if open and p.state == Player.State.NORMAL:
			p.lock(true)
		elif not open and p.state == Player.State.LOCKED:
			p.lock(false)


func notify(text: String) -> void:
	var l := UITheme.label(text, 28, UITheme.TEXT, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_constant_override("outline_size", 8)
	notifications.add_child(l)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func show_area_title(title: String, subtitle: String) -> void:
	for c in area_label.get_children():
		c.queue_free()
	var t := UITheme.label(title.to_upper(), 86, Color(0.95, 0.93, 0.88), true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 10)
	area_label.add_child(t)
	var orn := UITheme.ornament(700, Color(0.95, 0.93, 0.88))
	area_label.add_child(orn)
	var s := UITheme.label(subtitle, 36, UITheme.DIM, true)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_label.add_child(s)
	AudioManager.play_sfx("area_title")
	var tw := create_tween()
	tw.tween_property(area_label, "modulate:a", 1.0, 1.2)
	tw.tween_interval(2.4)
	tw.tween_property(area_label, "modulate:a", 0.0, 1.4)


func show_room_name(name: String) -> void:
	if name == "":
		return
	for c in area_label.get_children():
		c.queue_free()
	var s := UITheme.label(name, 40, Color(0.9, 0.9, 0.85), true)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_constant_override("outline_size", 8)
	area_label.add_child(s)
	var tw := create_tween()
	tw.tween_property(area_label, "modulate:a", 0.85, 0.6)
	tw.tween_interval(1.6)
	tw.tween_property(area_label, "modulate:a", 0.0, 0.8)


## Pantalla de texto a pantalla completa (intro / final).
func intro(lines: Array, footer := "") -> void:
	var layer_node := CanvasLayer.new()
	layer_node.layer = 60
	layer_node.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer_node)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer_node.add_child(bg)
	var label := UITheme.label("", 46, Color(0.9, 0.88, 0.82), false)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.offset_left = 260
	label.offset_right = -260
	layer_node.add_child(label)
	var hint := UITheme.label(footer if footer != "" else "[%s] Continuar" % Settings.key_name("jump"), 24, UITheme.DIM)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-300, -90)
	hint.custom_minimum_size = Vector2(600, 0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer_node.add_child(hint)
	for line in lines:
		label.text = str(line)
		label.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(label, "modulate:a", 1.0, 1.0)
		await _wait_accept(0.6)
		var tw2 := create_tween()
		tw2.tween_property(label, "modulate:a", 0.0, 0.5)
		await tw2.finished
	layer_node.queue_free()


func _wait_accept(min_time: float) -> void:
	var start := Time.get_ticks_msec()
	while true:
		await get_tree().process_frame
		if Time.get_ticks_msec() - start < min_time * 1000.0:
			continue
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack"):
			return


func _on_enemy_defeated(enemy_id: String, kills: int) -> void:
	var e := ContentDB.enemy(enemy_id)
	if e.is_empty():
		return
	if kills == 1:
		notify("Bestiario: " + str(e.nombre))
	elif kills == int(e.derrotas_requeridas):
		notify("Lección descifrada: " + str(e.nombre))


func _on_charm_granted(id: String) -> void:
	var a := ContentDB.amuleto(id)
	notify("Amuleto obtenido: " + str(a.get("nombre", id)))


func boss_bar_show(title: String) -> void:
	boss_name = title
	boss_ratio = 1.0
	boss_ratio_shown = 1.0
	boss_bar.visible = true
	boss_bar.modulate.a = 0.0
	create_tween().tween_property(boss_bar, "modulate:a", 1.0, 1.0)


func boss_bar_set(ratio: float) -> void:
	boss_ratio = clampf(ratio, 0.0, 1.0)


func boss_bar_hide() -> void:
	var tw := create_tween()
	tw.tween_property(boss_bar, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func(): boss_bar.visible = false)


func _process(delta: float) -> void:
	if boss_bar.visible:
		boss_ratio_shown = move_toward(boss_ratio_shown, boss_ratio, delta * 0.5)
		boss_bar.queue_redraw()


func _draw_boss_bar() -> void:
	var w := 900.0
	var pos := Vector2((boss_bar.size.x - w) * 0.5, boss_bar.size.y - 90)
	boss_bar.draw_string(UITheme.title_font(), pos + Vector2(0, -14), boss_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, w, 30, Color(0.95, 0.9, 0.85))
	boss_bar.draw_rect(Rect2(pos, Vector2(w, 12)), Color(0, 0, 0, 0.7))
	boss_bar.draw_rect(Rect2(pos, Vector2(w * boss_ratio_shown, 12)), Color(0.85, 0.35, 0.3))
	boss_bar.draw_rect(Rect2(pos, Vector2(w * boss_ratio, 12)), Color(0.9, 0.85, 0.75))
	boss_bar.draw_rect(Rect2(pos - Vector2(2, 2), Vector2(w + 4, 16)), Color(0.85, 0.75, 0.5, 0.6), false, 2.0)


func _quit_to_menu() -> void:
	if RoomRouter.world:
		RoomRouter.world.autosave()
	get_tree().paused = false
	_modal_count = 0
	RoomRouter.current_room = null
	RoomRouter.world = null
	get_tree().change_scene_to_file("res://scenes/main.tscn")
