extends Control
## Menú principal: fondo animado de Qatu, 3 ranuras de partida y opciones.

var slots_box: VBoxContainer
var main_box: VBoxContainer
var credits_box: VBoxContainer
var options: OptionsMenu
var backdrop_view: SubViewportContainer
var t := 0.0
var confirm_delete := -1


func _ready() -> void:
	theme = UITheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	Engine.time_scale = 1.0
	_build_background()

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.custom_minimum_size = Vector2(1100, 0)
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)
	var title := UITheme.label("QATU", 170, Color(0.96, 0.94, 0.88), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 16)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	vb.add_child(title)
	var sub := UITheme.label("El Reino Compilado", 48, UITheme.GOLD, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	vb.add_child(UITheme.ornament(760, Color(0.96, 0.94, 0.88)))
	var course := UITheme.label("Desarrollo de Software 4 · Un Metroidvania educativo", 28, UITheme.DIM)
	course.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(course)
	var author_lbl := UITheme.label("Autor: Rodrigo Machaca Aruquipa", 24, UITheme.GOLD)
	author_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(author_lbl)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vb.add_child(spacer)

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 14)
	main_box.custom_minimum_size = Vector2(520, 0)
	main_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(main_box)
	var play := _btn(main_box, "Jugar", _show_slots)
	_btn(main_box, "Opciones", func(): options.open())
	_btn(main_box, "Créditos", _show_credits)
	_btn(main_box, "Salir", func(): get_tree().quit())

	slots_box = VBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 14)
	slots_box.custom_minimum_size = Vector2(900, 0)
	slots_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slots_box.visible = false
	vb.add_child(slots_box)

	credits_box = VBoxContainer.new()
	credits_box.add_theme_constant_override("separation", 10)
	credits_box.custom_minimum_size = Vector2(520, 0)
	credits_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credits_box.visible = false
	vb.add_child(credits_box)
	_build_credits()

	options = OptionsMenu.new()
	add_child(options)
	options.closed.connect(func(_r): play.grab_focus())

	var hint := UITheme.label("Flechas: moverse · Z: saltar · X: atacar · C: Event Listener · F: curar · ↑: interactuar · Tab: mapa · I: Códice", 22, UITheme.DIM)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.custom_minimum_size = Vector2(1600, 0)
	hint.position = Vector2(-800, -70)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	AudioManager.play_music("hub")
	await get_tree().process_frame
	play.grab_focus()


func _build_background() -> void:
	backdrop_view = SubViewportContainer.new()
	backdrop_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop_view.stretch = true
	backdrop_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop_view)
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.use_hdr_2d = true
	backdrop_view.add_child(vp)
	var sky := ColorRect.new()
	var th := Themes.get_theme("hub")
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform vec4 a : source_color; uniform vec4 b : source_color; void fragment(){ COLOR = mix(a, b, UV.y); }"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("a", th.sky_top)
	mat.set_shader_parameter("b", th.sky_bottom)
	sky.material = mat
	sky.size = Vector2(1920, 1080)
	vp.add_child(sky)
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	cam.name = "Cam"
	vp.add_child(cam)
	var bd := Backdrop.new()
	vp.add_child(bd)
	bd.build(th, Vector2(5200, 1300), 42)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_hdr_threshold = 1.0
	we.environment = e
	vp.add_child(we)
	var dust := CPUParticles2D.new()
	dust.texture = FX.dot_texture()
	dust.amount = 80
	dust.lifetime = 10.0
	dust.preprocess = 10.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(1100, 600)
	dust.position = Vector2(960, 540)
	dust.gravity = Vector2(8, -10)
	dust.initial_velocity_max = 20.0
	dust.scale_amount_min = 0.08
	dust.scale_amount_max = 0.2
	dust.color = th.spore
	vp.add_child(dust)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _process(delta: float) -> void:
	t += delta
	var cam: Camera2D = backdrop_view.get_child(0).get_node("Cam")
	cam.position = Vector2(fmod(t * 40.0, 3000.0), 220 + sin(t * 0.1) * 20)


func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", UITheme.title_font())
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(cb)
	b.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
	parent.add_child(b)
	return b


func _show_slots() -> void:
	main_box.visible = false
	slots_box.visible = true
	_fill_slots()


func _fill_slots() -> void:
	for c in slots_box.get_children():
		slots_box.remove_child(c)
		c.queue_free()
	var first: Button
	for slot in [1, 2, 3]:
		var summary := SaveSystem.slot_summary(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		slots_box.add_child(row)
		var text := "Partida %d  ·  Nueva partida" % slot
		if summary.get("corrupt", false):
			text = "Partida %d  ·  Partida dañada (empezar de nuevo)" % slot
		elif not summary.is_empty():
			var gs_tmp := {"play_time": int(summary.get("play_time", 0)), "tablillas": summary.get("tablillas", []).size()}
			var secs: int = gs_tmp.play_time
			text = "Partida %d  ·  %d/12 tablillas  ·  %d:%02d  ·  %s" % [slot, gs_tmp.tablillas, secs / 3600, (secs / 60) % 60, "Bosque del DOM" if str(summary.get("bench_room", "")).begins_with("z3") else "Plaza de Qatu"]
		var b := _btn(row, text, _start.bind(slot, summary.is_empty() or summary.get("corrupt", false)))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if first == null:
			first = b
		if not summary.is_empty():
			var del := _btn(row, "Borrar" if confirm_delete != slot else "¿Seguro?", func():
				if confirm_delete == slot:
					SaveSystem.delete_slot(slot)
					confirm_delete = -1
				else:
					confirm_delete = slot
				_fill_slots())
			del.custom_minimum_size = Vector2(200, 0)
	var back := _btn(slots_box, "Volver", func():
		slots_box.visible = false
		main_box.visible = true
		(main_box.get_child(0) as Button).grab_focus())
	await get_tree().process_frame
	if first:
		first.grab_focus()


func _start(slot: int, is_new: bool) -> void:
	GameState.pending_start = {"slot": slot, "new": is_new}
	AudioManager.play_sfx("area_title")
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.8)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _build_credits() -> void:
	var style := UITheme.panel_style(0.92)
	style.set_content_margin_all(14)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	credits_box.add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)

	var dev_intro := UITheme.label("Diseñado y desarrollado por", 20, UITheme.DIM)
	dev_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(dev_intro)

	var dev_name := UITheme.label("Rodrigo Machaca Aruquipa", 30, UITheme.GOLD, true)
	dev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(dev_name)

	var course_lbl := UITheme.label("Desarrollo de Software 4 · Jala University", 18, UITheme.DIM)
	course_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(course_lbl)

	inner.add_child(UITheme.ornament(240))

	var link_btn := Button.new()
	link_btn.text = "Visitar portafolio web"
	link_btn.add_theme_font_override("font", UITheme.body_font())
	link_btn.add_theme_font_size_override("font_size", 22)
	link_btn.pressed.connect(func(): OS.shell_open("https://rodrigo-tech-portfolio-v2.vercel.app/"))
	link_btn.focus_entered.connect(func(): AudioManager.play_sfx("ui_move"))
	inner.add_child(link_btn)

	_btn(inner, "Volver", func():
		credits_box.visible = false
		main_box.visible = true
		(main_box.get_child(0) as Button).grab_focus()
	)


func _show_credits() -> void:
	main_box.visible = false
	credits_box.visible = true
	var p: PanelContainer = credits_box.get_child(0) as PanelContainer
	var inner: VBoxContainer = p.get_child(0) as VBoxContainer
	for child in inner.get_children():
		if child is Button:
			(child as Button).grab_focus()
			break


func _unhandled_input(event: InputEvent) -> void:
	if options.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if slots_box.visible:
			slots_box.visible = false
			main_box.visible = true
			(main_box.get_child(0) as Button).grab_focus()
		elif credits_box and credits_box.visible:
			credits_box.visible = false
			main_box.visible = true
			(main_box.get_child(0) as Button).grab_focus()

