extends Node2D
## Escena de juego: contiene la sala actual, el jugador, la cámara, la
## iluminación global y la interfaz. Orquesta muerte, guardado y pausa.

var room_holder: Node2D
var player: Player
var camera: ShakeCamera
var ui: GameUI
var sky_rect: TextureRect
var modulate_node: CanvasModulate
var spores: CPUParticles2D
var env: WorldEnvironment
var _hitstop_active := false


func _ready() -> void:
	add_to_group("world")
	RoomRouter.world = self

	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -100
	add_child(sky_layer)
	sky_rect = TextureRect.new()
	sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_rect.stretch_mode = TextureRect.STRETCH_SCALE
	sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_layer.add_child(sky_rect)

	room_holder = Node2D.new()
	room_holder.name = "Room"
	add_child(room_holder)

	player = Player.new()
	player.name = "Player"
	player.z_index = 10
	add_child(player)
	player.died.connect(_on_player_died)

	camera = ShakeCamera.new()
	camera.target = player
	add_child(camera)
	camera.make_current()

	spores = CPUParticles2D.new()
	spores.texture = FX.dot_texture()
	spores.amount = 70
	spores.lifetime = 9.0
	spores.preprocess = 9.0
	spores.local_coords = false
	spores.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spores.emission_rect_extents = Vector2(1200, 700)
	spores.direction = Vector2(0.3, -1)
	spores.spread = 60.0
	spores.gravity = Vector2(6, -12)
	spores.initial_velocity_min = 4.0
	spores.initial_velocity_max = 22.0
	spores.scale_amount_min = 0.08
	spores.scale_amount_max = 0.22
	spores.color_ramp = _spore_ramp()
	spores.z_index = 20
	camera.add_child(spores)

	modulate_node = CanvasModulate.new()
	add_child(modulate_node)

	env = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_strength = 1.0
	e.glow_bloom = 0.04
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	e.set_glow_level(1, 1.0)
	e.set_glow_level(2, 1.0)
	e.set_glow_level(3, 0.6)
	e.set_glow_level(4, 0.3)
	e.glow_hdr_threshold = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = e
	add_child(env)

	ui = GameUI.new()
	add_child(ui)

	Events.hitstop.connect(_on_hitstop)
	Events.sello_resolved.connect(func(_id): autosave())
	Events.ability_granted.connect(func(_id): autosave())
	Events.boss_defeated.connect(func(_id): autosave())

	_start_game()


func _spore_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	return g


func _start_game() -> void:
	var start: Dictionary = GameState.pending_start
	GameState.slot = int(start.get("slot", 1))
	if start.get("new", true):
		GameState.new_game()
		player.lock(true)
		await ui.fade.fade_to(1.0, 0.0)
		await ui.intro(ContentDB.dialogo("intro"))
		await RoomRouter.go_to("hub_plaza", "inicio", false)
		autosave()
		await fade_in(1.2)
		await get_tree().create_timer(3.5).timeout
		ui.notify("Acércate a la Mentora y pulsa [%s] para hablar" % Settings.key_name("look_up"))
	else:
		var d := SaveSystem.load_slot(GameState.slot)
		if d.is_empty():
			GameState.new_game()
		else:
			GameState.from_dict(d)
		await ui.fade.fade_to(1.0, 0.0)
		await RoomRouter.go_to(GameState.data.bench_room, GameState.data.bench_id, false)
		await fade_in(0.8)


func on_room_loaded(room: RoomBase, first_visit: bool) -> void:
	var th := room.theme()
	var g := Gradient.new()
	g.colors = PackedColorArray([th.sky_top, th.sky_bottom])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 256
	sky_rect.texture = gt
	modulate_node.color = th.ambient
	spores.color = th.spore
	if ui.boss_bar.visible:
		ui.boss_bar_hide()
	camera.set_room_limits(room.size_px())
	camera.snap_to_target()
	AudioManager.play_music(room.music())
	_spawn_shade(room)
	_schedule_manual_intro(room)
	if first_visit and room.area_title != "":
		ui.show_area_title(room.area_title, room.display_name)
	elif first_visit:
		ui.show_room_name(room.display_name)
	autosave()


## El Manual se presenta solo si el jugador sigue en la misma sala.
func _schedule_manual_intro(room: RoomBase) -> void:
	if room.get_entity("manual") == null or GameState.get_flag("guia:%s:intro" % room.room_id):
		return
	await get_tree().create_timer(1.6).timeout
	while is_instance_valid(room) and RoomRouter.current_room == room and (RoomRouter.transitioning or ui.is_modal_open()):
		await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(room) or RoomRouter.current_room != room or room.is_queued_for_deletion():
		return
	var manual = room.get_entity("manual")
	if is_instance_valid(manual) and player.state != Player.State.DEAD:
		await manual.auto_intro(ui)


func _spawn_shade(room: RoomBase) -> void:
	var shade = GameState.data.shade
	if shade == null or shade.room != room.room_id:
		return
	var s: Node2D = load("res://scripts/enemies/conflicto_merge.gd").new()
	room.add_runtime_entity("conflicto_merge", s)
	s.global_position = Vector2(shade.x, shade.y)


func autosave() -> void:
	SaveSystem.save_slot(GameState.slot, GameState.to_dict())


# --- Fundidos -------------------------------------------------------------------------

func fade_out(duration := 0.3) -> void:
	await ui.fade.fade_to(1.0, duration)


func fade_in(duration := 0.3) -> void:
	await ui.fade.fade_to(0.0, duration)


# --- Hit-stop --------------------------------------------------------------------------

func _on_hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false


# --- Muerte -----------------------------------------------------------------------------

func _on_player_died() -> void:
	var room_id: String = RoomRouter.current_room.room_id if RoomRouter.current_room else GameState.data.room
	var pos := player.global_position
	if RoomRouter.current_room and RoomRouter.current_room.has_method("safe_shade_position"):
		pos = RoomRouter.current_room.safe_shade_position(pos)
	GameState.on_death(room_id, pos + Vector2(0, -60))
	await fade_out(0.8)
	player.refill_after_respawn()
	await RoomRouter.go_to(GameState.data.bench_room, GameState.data.bench_id, false)
	autosave()
	await fade_in(0.8)


# --- Entrada global ------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if ui.is_modal_open() or RoomRouter.transitioning:
		return
	if event.is_action_pressed("pause"):
		ui.open_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("codice"):
		ui.open_codice()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map"):
		ui.show_map(true)
	elif event.is_action_released("map"):
		ui.show_map(false)
