class_name Player
extends CharacterBody2D
## El Aprendiz. Movimiento preciso, Cursor en tres direcciones con pogo,
## Hotfix (curación), Event Listener (gancho) e interacción.

enum State { NORMAL, GRAPPLE, HURT, HEAL, DEAD, LOCKED }

signal died

var tuning := PlayerTuning.new()
var state := State.NORMAL
var facing := 1.0
var invuln := 0.0

var rig: PlayerRig
var attack_area: Area2D
var interact_area: Area2D
var hurtbox: Area2D
var light: PointLight2D

var _coyote := 0.0
var _buffer := 0.0
var _attack_cd := 0.0
var _attack_active := 0.0
var _attack_dir := Vector2.RIGHT
var _attack_hits: Array = []
## Golpes seguidos de la Hoja JWT (el tercero va firmado).
var _combo_hits := 0
var _combo_t := 0.0

const DEFAULT_WEAPON := {"id": "cursor", "nombre": "Cursor", "estilo": "corte", "dano": 1, "alcance": 1.0, "cadencia": 1.0, "color": [2.5, 2.6, 2.8]}
var _recoil := 0.0
var _recoil_vel := 0.0
var _hurt_t := 0.0
var _heal_t := 0.0
var _grapple_target: Node2D
var _grapple_t := 0.0
var _grapple_cd := 0.0
var _targeted_anchor: Node2D
var _was_on_floor := true
var _fall_speed := 0.0
var _safe_pos := Vector2.ZERO
var _safe_timer := 0.0
var _auto_walk := 0.0
var _dead_t := 0.0
var _hazard_respawning := false
var _pogo_rise := false

## Habilidad Caché: posición guardada y tiempo de vida restante (0 = sin caché).
const CACHE_TTL := 6.0
var cache_pos := Vector2.ZERO
var cache_ttl := 0.0
var _cache_marker: CacheMarker

## Habilidad Tokens: access token con alcance y caducidad, y refresh token.
const TOKEN_TTL := 12.0
const REFRESH_COOLDOWN := 2.0
var token_ttl := 0.0
var token_scope := ""
var has_refresh := false
var _refresh_cd := 0.0
var _token_badge: TokenBadge
var _mfa_used := false

## Habilidad REST Dash (zona 1): impulso horizontal. Al atravesar un terminal
## REST le envía la petición.
const DASH_SPEED := 1150.0
const DASH_TIME := 0.17
const DASH_COOLDOWN := 0.45
var _dash_t := 0.0
var _dash_cd := 0.0
var _air_dash_used := false

## Habilidad Contenedor (zona 8): despliega un Pod temporal bajo los pies.
const POD_TTL := 3.5
var _pod: Node2D
var _air_pod_used := false

## Habilidad Inspector (zona 9): revela aserciones durante unos segundos.
const INSPECT_TIME := 6.0
const INSPECT_RANGE := 360.0
var inspect_t := 0.0
var _inspector_lens: InspectorLens


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1 << 1
	collision_mask = 1
	floor_snap_length = 12.0
	floor_max_angle = deg_to_rad(50)

	var cs := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 17
	cap.height = 76
	cs.shape = cap
	cs.position = Vector2(0, -38)
	add_child(cs)

	rig = PlayerRig.new()
	rig.player = self
	rig.z_index = 10
	add_child(rig)

	light = FX.make_light(Color(0.75, 0.9, 1.0), 2.4, 0.55)
	light.position = Vector2(0, -50)
	light.remove_from_group("light_source")
	add_child(light)

	hurtbox = Area2D.new()
	hurtbox.collision_layer = 1 << 3
	hurtbox.collision_mask = 1 << 6
	hurtbox.monitorable = false
	var hcs := CollisionShape2D.new()
	var hshape := RectangleShape2D.new()
	hshape.size = Vector2(26, 64)
	hcs.shape = hshape
	hcs.position = Vector2(0, -36)
	hurtbox.add_child(hcs)
	add_child(hurtbox)

	attack_area = Area2D.new()
	attack_area.collision_layer = 1 << 5
	attack_area.collision_mask = 1 << 4
	attack_area.monitorable = false
	var acs := CollisionShape2D.new()
	acs.shape = RectangleShape2D.new()
	attack_area.add_child(acs)
	add_child(attack_area)

	interact_area = Area2D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 1 << 7
	interact_area.monitorable = false
	var ics := CollisionShape2D.new()
	var ishape := RectangleShape2D.new()
	ishape.size = Vector2(60, 90)
	ics.shape = ishape
	ics.position = Vector2(0, -45)
	interact_area.add_child(ics)
	add_child(interact_area)

	_safe_pos = global_position

	_cache_marker = CacheMarker.new()
	_cache_marker.player = self
	_cache_marker.top_level = true
	_cache_marker.z_index = 9
	add_child(_cache_marker)

	_token_badge = TokenBadge.new()
	_token_badge.player = self
	_token_badge.z_index = 11
	add_child(_token_badge)

	_inspector_lens = InspectorLens.new()
	_inspector_lens.player = self
	_inspector_lens.z_index = 8
	add_child(_inspector_lens)


# --- REST Dash ------------------------------------------------------------------------

func is_dashing() -> bool:
	return _dash_t > 0.0


## Lanza el impulso hacia donde se mira. En el aire, uno por salto.
func start_dash() -> bool:
	if not GameState.has_ability("rest_dash") or _dash_cd > 0.0 or state != State.NORMAL:
		return false
	if not is_on_floor():
		if _air_dash_used:
			return false
		_air_dash_used = true
	_dash_t = DASH_TIME
	_dash_cd = DASH_COOLDOWN
	velocity = Vector2(facing * DASH_SPEED, 0.0)
	rig.do_squash(Vector2(1.35, 0.8))
	AudioManager.play_sfx("grapple", 0.1)
	FX.dust(get_parent(), global_position, 8)
	return true


# --- Contenedor -----------------------------------------------------------------------

## Despliega un Pod bajo los pies. Solo en el aire, uno por salto.
func deploy_pod() -> bool:
	if not GameState.has_ability("contenedor") or state != State.NORMAL:
		return false
	if is_on_floor():
		Events.notify.emit("Salta y pulsa [%s] en el aire: el Pod aparece bajo tus pies" % Settings.key_name("contenedor"))
		return false
	if _air_pod_used:
		return false
	_air_pod_used = true
	if is_instance_valid(_pod):
		_pod.queue_free()
	var pod := PodPlatform.new()
	pod.ttl = POD_TTL
	get_parent().add_child(pod)
	pod.global_position = global_position + Vector2(0, 2)
	_pod = pod
	velocity.y = minf(velocity.y, 0.0)
	AudioManager.play_sfx("node_on", 0.1)
	return true


func active_pod() -> Node2D:
	return _pod if is_instance_valid(_pod) else null


# --- Inspector ------------------------------------------------------------------------

func inspecting() -> bool:
	return inspect_t > 0.0


func start_inspect() -> bool:
	if not GameState.has_ability("inspector") or inspect_t > 0.0:
		return false
	inspect_t = INSPECT_TIME
	AudioManager.play_sfx("laser", 0.2)
	return true


# --- Tokens ---------------------------------------------------------------------------

func token_ttl_max() -> float:
	return TOKEN_TTL * (1.5 if GameState.is_charm_equipped("sso") else 1.0)


## ¿Hay un access token vigente con el alcance pedido? ("" = cualquiera)
func token_valid(scope := "") -> bool:
	if token_ttl <= 0.0:
		return false
	return scope == "" or scope == token_scope


## Emite un access token (y el refresh token) desde un autorizador.
func grant_token(scope: String, ttl := 0.0, refresh := true) -> void:
	token_scope = scope
	token_ttl = ttl if ttl > 0.0 else token_ttl_max()
	if refresh:
		has_refresh = true
	AudioManager.play_sfx("node_on", 0.05)
	FX.burst(get_parent(), global_position + Vector2(0, -50), Color(2.4, 1.9, 0.8), 18, 300.0, 0.5, 0.35, Vector2.ZERO)


## Renueva el access token con el refresh token. Devuelve si se renovó.
func refresh_access_token() -> bool:
	if not has_refresh or _refresh_cd > 0.0 or token_scope == "":
		return false
	token_ttl = token_ttl_max()
	_refresh_cd = REFRESH_COOLDOWN
	AudioManager.play_sfx("gate_open", 0.1)
	FX.burst(get_parent(), global_position + Vector2(0, -50), Color(0.8, 2.2, 2.4), 14, 260.0, 0.4, 0.35, Vector2.ZERO)
	return true


## Un ladrón de tokens revoca el access token (el refresh sigue siendo válido).
func revoke_token() -> void:
	if token_ttl <= 0.0:
		return
	token_ttl = 0.0
	Events.notify.emit("¡Te robaron el access token! Renuévalo con [%s]" % Settings.key_name("token"))
	AudioManager.play_sfx("sello_bad", 0.1)


func _use_token() -> void:
	if not GameState.has_ability("token"):
		return
	if not refresh_access_token():
		if not has_refresh:
			Events.notify.emit("Todavía no tienes refresh token: consíguelo en un autorizador")
		elif _refresh_cd > 0.0:
			Events.notify.emit("Espera un momento antes de volver a renovar")


# --- Caché ---------------------------------------------------------------------------

func cache_ttl_max() -> float:
	return CACHE_TTL * (2.0 if GameState.is_charm_equipped("cdn") else 1.0)


func has_cache() -> bool:
	return cache_ttl > 0.0


## Guarda la posición actual (solo en el suelo). Devuelve si se guardó.
func cache_store() -> bool:
	if not GameState.has_ability("cache") or not is_on_floor() or state != State.NORMAL:
		return false
	cache_pos = global_position
	cache_ttl = cache_ttl_max()
	AudioManager.play_sfx("node_on", 0.05)
	FX.burst(get_parent(), cache_pos + Vector2(0, -40), Color(1.0, 1.6, 2.6), 16, 260.0, 0.4, 0.35, Vector2.ZERO)
	return true


## Vuelve a la posición guardada si la caché sigue vigente.
func cache_restore() -> bool:
	if not has_cache():
		return false
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(1.0, 1.6, 2.6), 18, 320.0, 0.4, 0.35, Vector2.ZERO)
	global_position = cache_pos
	velocity = Vector2.ZERO
	_safe_pos = cache_pos
	cache_ttl = 0.0
	invuln = maxf(invuln, 0.3)
	rig.do_squash(Vector2(1.3, 0.75))
	AudioManager.play_sfx("gate_open", 0.1)
	FX.burst(get_parent(), cache_pos + Vector2(0, -40), Color(1.4, 2.0, 2.8), 24, 380.0, 0.5, 0.4, Vector2.ZERO)
	return true


func cache_invalidate() -> void:
	cache_ttl = 0.0


func _use_cache() -> void:
	if not GameState.has_ability("cache"):
		return
	if has_cache():
		cache_restore()
	elif not cache_store():
		Events.notify.emit("Solo puedes guardar la caché con los pies en el suelo")


# --- API pública ---------------------------------------------------------------

func lock(locked: bool) -> void:
	if locked:
		if state != State.DEAD:
			state = State.LOCKED
			velocity.x = 0.0
			rig.heal_glow = 0.0
	elif state == State.LOCKED:
		state = State.NORMAL


func is_locked() -> bool:
	return state == State.LOCKED


func place_at(pos: Vector2, walk_dir := 0.0) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_safe_pos = pos
	cache_invalidate()
	_mfa_used = false
	_dash_t = 0.0
	if walk_dir != 0.0:
		facing = signf(walk_dir)
		_auto_walk = 0.22


func look_intent() -> int:
	if state != State.NORMAL or absf(velocity.x) > 10.0 or not is_on_floor():
		return 0
	if Input.is_action_pressed("look_down"):
		return 1
	if Input.is_action_pressed("look_up") and _nearest_interactable() == null:
		return -1
	return 0


func grapple_range() -> float:
	var r := tuning.grapple_range
	if GameState.is_charm_equipped("delegacion"):
		r *= 1.5
	return r


func take_damage(amount: int, from_pos: Vector2, hazard := false) -> void:
	if state == State.DEAD or invuln > 0.0 or _hazard_respawning:
		return
	if state == State.LOCKED:
		return
	# Amuleto MFA: el primer golpe de cada sala no quita máscara (segundo factor).
	if GameState.is_charm_equipped("mfa") and not _mfa_used:
		_mfa_used = true
		invuln = tuning.invuln_time
		rig.flash = 1.0
		AudioManager.play_sfx("sello_ok", 0.1)
		Events.notify.emit("Segundo factor: el golpe no te alcanzó")
		FX.burst(get_parent(), global_position + Vector2(0, -40), Color(2.4, 2.0, 0.9), 16, 320.0, 0.5, 0.35, Vector2.ZERO)
		return
	var died_now := GameState.damage(amount)
	AudioManager.play_sfx("hurt")
	Events.hitstop.emit(0.12)
	Events.camera_shake.emit(16.0, 0.3)
	rig.flash = 1.0
	rig.heal_glow = 0.0
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(1.0, 1.0, 1.0, 0.9), 14, 420.0, 0.45)
	var mult := 1.4 if GameState.is_charm_equipped("box_model") else 1.0
	invuln = tuning.invuln_time * mult
	if died_now:
		_die()
		return
	if hazard:
		_hazard_respawn()
		return
	state = State.HURT
	_hurt_t = tuning.hurt_time
	var dir := signf(global_position.x - from_pos.x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(dir * tuning.hurt_knockback.x, tuning.hurt_knockback.y)


func refill_after_respawn() -> void:
	state = State.NORMAL
	rig.dissolve = 0.0
	rig.visible = true
	invuln = 0.6
	_dead_t = 0.0


# --- Bucle -------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	invuln = maxf(0.0, invuln - delta)
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_combo_t = maxf(0.0, _combo_t - delta)
	_grapple_cd = maxf(0.0, _grapple_cd - delta)
	_recoil = maxf(0.0, _recoil - delta)
	_coyote = maxf(0.0, _coyote - delta)
	_buffer = maxf(0.0, _buffer - delta)
	if cache_ttl > 0.0:
		cache_ttl -= delta
		if cache_ttl <= 0.0:
			cache_ttl = 0.0
			AudioManager.play_sfx("sello_bad", 0.1)
	_refresh_cd = maxf(0.0, _refresh_cd - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	inspect_t = maxf(0.0, inspect_t - delta)
	if is_on_floor():
		_air_dash_used = false
		_air_pod_used = false
	if token_ttl > 0.0:
		token_ttl = maxf(0.0, token_ttl - delta)
		if token_ttl == 0.0:
			AudioManager.play_sfx("sello_bad", 0.1)
			Events.notify.emit("El access token caducó. Pulsa [%s] para renovarlo" % Settings.key_name("token"))

	match state:
		State.NORMAL:
			_state_normal(delta)
		State.GRAPPLE:
			_state_grapple(delta)
		State.HURT:
			_hurt_t -= delta
			_apply_gravity(delta, false)
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
			move_and_slide()
			if _hurt_t <= 0.0:
				state = State.NORMAL
		State.HEAL:
			_state_heal(delta)
		State.DEAD:
			_dead_t += delta
			velocity = Vector2.ZERO
			rig.dissolve = clampf((_dead_t - 0.35) / 0.9, 0.0, 1.0)
			if _dead_t > 1.4 and _dead_t - delta <= 1.4:
				died.emit()
				Events.player_died.emit()
		State.LOCKED:
			_apply_gravity(delta, false)
			velocity.x = move_toward(velocity.x, 0.0, tuning.ground_decel * delta)
			move_and_slide()

	_update_attack(delta)
	_check_hurtbox()
	_update_anchor_target()
	_landing_fx()
	_track_safe_position(delta)


func _state_normal(delta: float) -> void:
	if _dash_t > 0.0:
		_dash_t -= delta
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		move_and_slide()
		if is_on_wall():
			_dash_t = 0.0
		return
	var axis := Input.get_axis("move_left", "move_right")
	if _auto_walk > 0.0:
		_auto_walk -= delta
		axis = facing
	if absf(axis) < 0.2:
		axis = 0.0
	var target := signf(axis) * tuning.run_speed
	var accel: float
	if is_on_floor():
		accel = tuning.ground_accel if axis != 0.0 else tuning.ground_decel
	else:
		accel = tuning.air_accel
	velocity.x = move_toward(velocity.x, target, accel * delta)
	if _recoil > 0.0:
		velocity.x = _recoil_vel
	if axis != 0.0 and _attack_active <= 0.0:
		facing = signf(axis)

	if is_on_floor():
		_coyote = tuning.coyote_time
	if Input.is_action_just_pressed("jump"):
		_buffer = tuning.jump_buffer
	if _buffer > 0.0 and (is_on_floor() or _coyote > 0.0):
		velocity.y = tuning.jump_velocity
		_buffer = 0.0
		_coyote = 0.0
		rig.do_squash(Vector2(0.75, 1.3))
		FX.dust(get_parent(), global_position, 6)
		AudioManager.play_sfx("jump")
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= tuning.jump_cut

	_apply_gravity(delta, Input.is_action_pressed("jump"))

	if Input.is_action_just_pressed("attack") and _attack_cd <= 0.0:
		_start_attack()
	if Input.is_action_just_pressed("arma") and GameState.data.armas.size() > 1:
		GameState.cycle_weapon()
		AudioManager.play_sfx("charm_on", 0.1)
		Events.notify.emit("Arma: %s" % str(weapon().get("nombre", "Cursor")))
	if Input.is_action_just_pressed("grapple") and _grapple_cd <= 0.0:
		_try_grapple()
	if Input.is_action_just_pressed("cache"):
		_use_cache()
	if Input.is_action_just_pressed("token"):
		_use_token()
	if Input.is_action_just_pressed("dash") and start_dash():
		move_and_slide()
		return
	if Input.is_action_just_pressed("contenedor"):
		deploy_pod()
	if Input.is_action_just_pressed("inspector"):
		start_inspect()
	if Input.is_action_pressed("heal") and is_on_floor() and GameState.can_heal() and _attack_active <= 0.0:
		state = State.HEAL
		_heal_t = 0.0
		velocity.x = 0.0
		AudioManager.play_sfx("heal_charge")
	if Input.is_action_just_pressed("look_up") and is_on_floor():
		var it := _nearest_interactable()
		if it:
			velocity.x = 0.0
			it.interact(self)
			return

	move_and_slide()


func _apply_gravity(delta: float, jump_held: bool) -> void:
	var g := tuning.gravity
	if velocity.y >= 0.0:
		_pogo_rise = false
	# El rebote del pogo sube completo aunque no se mantenga el salto.
	if velocity.y > 0.0 or not (jump_held or _pogo_rise):
		g *= tuning.fall_gravity_mult
	velocity.y = minf(velocity.y + g * delta, tuning.max_fall)


func _landing_fx() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and _fall_speed > 500.0:
		var k := clampf(_fall_speed / tuning.max_fall, 0.0, 1.0)
		rig.do_squash(Vector2(1.0 + 0.35 * k, 1.0 - 0.3 * k))
		FX.dust(get_parent(), global_position, int(6 + 8 * k))
		AudioManager.play_sfx("land")
	_fall_speed = velocity.y if not on_floor else 0.0
	_was_on_floor = on_floor


# --- Ataque --------------------------------------------------------------------------

## Arma equipada (datos de content/armas/armas.json).
func weapon() -> Dictionary:
	var w := ContentDB.arma(str(GameState.data.get("arma", "cursor")))
	return w if not w.is_empty() else DEFAULT_WEAPON


func weapon_color() -> Color:
	var c: Array = weapon().get("color", [2.5, 2.6, 2.8])
	return Color(float(c[0]), float(c[1]), float(c[2]))


func _start_attack() -> void:
	var w := weapon()
	var estilo := str(w.get("estilo", "corte"))
	var alcance := float(w.get("alcance", 1.0))
	_attack_cd = tuning.attack_cooldown * float(w.get("cadencia", 1.0))
	_attack_active = tuning.attack_active
	_attack_hits.clear()
	if Input.is_action_pressed("look_up"):
		_attack_dir = Vector2.UP
	elif Input.is_action_pressed("look_down") and not is_on_floor():
		_attack_dir = Vector2.DOWN
	else:
		_attack_dir = Vector2(facing, 0)
	var cs: CollisionShape2D = attack_area.get_child(0)
	var shape: RectangleShape2D = cs.shape
	var vk := clampf(alcance, 0.85, 1.35)
	if _attack_dir.y == 0.0:
		var length := 130.0 * alcance
		shape.size = Vector2(length, 60.0 if estilo == "estocada" else 90.0)
		cs.position = Vector2(facing * (7.0 + length * 0.5), -44)
		if estilo == "barrido":
			shape.size = Vector2(length * 2.0, 100)
			cs.position = Vector2(0, -44)
		elif estilo == "distancia":
			shape.size = Vector2(40, 60)
			cs.position = Vector2(facing * 30, -44)
			WeaponShots.bolt(get_parent(), global_position + Vector2(facing * 40, -46), facing, int(w.get("dano", 1)), weapon_color())
		elif estilo == "pesado" and is_on_floor():
			var dmg := int(w.get("dano", 1))
			var pos := global_position + Vector2(facing * 70, -6)
			var col := weapon_color()
			var dir := facing
			get_tree().create_timer(0.1).timeout.connect(func() -> void:
				if is_instance_valid(self):
					WeaponShots.wave(get_parent(), pos, dir, maxi(1, dmg - 1), col))
	elif _attack_dir.y < 0.0:
		shape.size = Vector2(110, 130 * vk)
		cs.position = Vector2(0, -55 - 65 * vk)
	else:
		shape.size = Vector2(100, 120 * vk)
		cs.position = Vector2(0, -20 + 60 * vk)
	rig.play_slash(_attack_dir, w)
	AudioManager.play_sfx("slash", 0.06 if float(w.get("cadencia", 1.0)) >= 0.9 else 0.2)


func _update_attack(delta: float) -> void:
	if _attack_active <= 0.0:
		return
	_attack_active -= delta
	if state == State.DEAD:
		return
	var got_pogo := false
	var got_recoil := false
	for area in attack_area.get_overlapping_areas():
		var target: Object = area if area.has_method("take_hit") else area.get_parent()
		if target == null or not target.has_method("take_hit") or target in _attack_hits:
			continue
		_attack_hits.append(target)
		var w := weapon()
		var estilo := str(w.get("estilo", "corte"))
		var dmg := int(w.get("dano", 1))
		var tgt_node := target as Node2D
		if estilo == "estocada" and tgt_node and absf(tgt_node.global_position.x - global_position.x) > 110.0:
			dmg += 1  # golpe con la punta
		var signed := false
		if estilo == "firma":
			_combo_hits = _combo_hits + 1 if _combo_t > 0.0 else 1
			_combo_t = 1.5
			if _combo_hits >= 3:
				dmg = 3
				_combo_hits = 0
				signed = true
		var knock := 1.8 if estilo == "ancla" else (1.3 if estilo == "pesado" else 1.0)
		var result: Dictionary = target.take_hit({"damage": dmg, "dir": _attack_dir, "source": self, "position": global_position, "knock": knock})
		if signed and result.get("solid", false):
			FX.burst(get_parent(), attack_area.get_child(0).global_position, Color(2.8, 2.4, 0.8), 18, 560.0, 0.4, 0.4, Vector2.ZERO)
			Events.hitstop.emit(0.06)
		if result.get("energy", false):
			var gain := tuning.energy_per_hit
			if estilo == "bisturi":
				gain *= 1.5
			if GameState.is_charm_equipped("media_query") and GameState.data.masks <= 2:
				gain *= 2.0
			GameState.add_energy(gain)
		if result.get("solid", false):
			got_recoil = true
			if _attack_dir == Vector2.DOWN and result.get("pogo", false):
				got_pogo = true
		var hit_pos: Vector2 = attack_area.get_child(0).global_position
		if result.get("spark", true):
			FX.burst(get_parent(), hit_pos, Color(2.2, 2.2, 2.4), 10, 520.0, 0.3, 0.3, Vector2.ZERO, _attack_dir, 50.0)
	if got_pogo:
		velocity.y = tuning.pogo_velocity
		_pogo_rise = true
		_coyote = 0.0
		rig.do_squash(Vector2(0.8, 1.2))
		AudioManager.play_sfx("pogo")
	elif got_recoil and _attack_dir.y == 0.0:
		_recoil = 0.08
		_recoil_vel = -facing * tuning.attack_recoil


# --- Curación ---------------------------------------------------------------------------

func _state_heal(delta: float) -> void:
	_apply_gravity(delta, false)
	velocity.x = 0.0
	move_and_slide()
	if not Input.is_action_pressed("heal") or not is_on_floor():
		state = State.NORMAL
		rig.heal_glow = 0.0
		return
	_heal_t += delta
	rig.heal_glow = clampf(_heal_t / (tuning.heal_time * (0.65 if GameState.is_charm_equipped("async_await") else 1.0)), 0.0, 1.0)
	if randf() < 0.4:
		FX.burst(get_parent(), global_position + Vector2(randf_range(-26, 26), -10), Color(0.8, 2.2, 2.4), 1, 120.0, 0.6, 0.3, Vector2(0, -200), Vector2.UP, 20.0)
	if _heal_t >= tuning.heal_time * (0.65 if GameState.is_charm_equipped("async_await") else 1.0):
		if GameState.try_consume_heal():
			GameState.heal(1)
			AudioManager.play_sfx("heal")
			rig.flash = 0.6
			FX.burst(get_parent(), global_position + Vector2(0, -40), Color(0.9, 2.4, 2.6), 22, 360.0, 0.6)
		_heal_t = 0.0
		if not GameState.can_heal():
			state = State.NORMAL
			rig.heal_glow = 0.0


# --- Event Listener (gancho) -------------------------------------------------------------

func _find_anchor() -> Node2D:
	if not GameState.has_ability("event_listener"):
		return null
	var best: Node2D = null
	var best_score := INF
	var rng := grapple_range()
	var origin := global_position + Vector2(0, -44)
	var space := get_world_2d().direct_space_state
	for a in get_tree().get_nodes_in_group("anchor"):
		if not a.is_inside_tree() or not a.can_grapple():
			continue
		var to: Vector2 = a.global_position - origin
		var dist := to.length()
		if dist > rng or dist < 30.0:
			continue
		var q := PhysicsRayQueryParameters2D.create(origin, a.global_position, 1)
		if not space.intersect_ray(q).is_empty():
			continue
		# Preferir nodos hacia donde se mira y, sobre todo, más altos.
		var score := dist
		if signf(to.x) != facing and absf(to.x) > 40.0:
			score += 260.0
		score += to.y * 0.7
		if score < best_score:
			best_score = score
			best = a
	return best


func _update_anchor_target() -> void:
	var t := _find_anchor() if state == State.NORMAL else null
	if t != _targeted_anchor:
		if is_instance_valid(_targeted_anchor):
			_targeted_anchor.set_targeted(false)
		_targeted_anchor = t
		if t:
			t.set_targeted(true)


func _try_grapple() -> void:
	var target := _find_anchor()
	if target == null:
		return
	_grapple_target = target
	_grapple_t = 0.0
	state = State.GRAPPLE
	target.on_grapple(self)
	AudioManager.play_sfx("grapple")
	rig.do_squash(Vector2(1.25, 0.8))


func _state_grapple(delta: float) -> void:
	_grapple_t += delta
	if not is_instance_valid(_grapple_target):
		state = State.NORMAL
		return
	var goal := _grapple_target.global_position + Vector2(0, 40)
	var to := goal - global_position
	var dir := to.normalized()
	velocity = dir * tuning.grapple_speed
	if absf(dir.x) > 0.2:
		facing = signf(dir.x)
	var before := global_position
	move_and_slide()
	var stuck := global_position.distance_to(before) < tuning.grapple_speed * delta * 0.25
	if to.length() < 46.0 or _grapple_t > tuning.grapple_max_time or (stuck and _grapple_t > 0.08):
		state = State.NORMAL
		velocity = dir * tuning.grapple_exit_speed
		if dir.y < -0.3:
			velocity.y = minf(velocity.y, -620.0)
		_coyote = 0.16
		_grapple_cd = 0.12
		_grapple_target.on_release()
		rig.do_squash(Vector2(0.8, 1.2))


# --- Daño, muerte, zona segura -------------------------------------------------------------

func _check_hurtbox() -> void:
	if state == State.DEAD or invuln > 0.0 or state == State.LOCKED:
		return
	for area in hurtbox.get_overlapping_areas():
		if not area.is_inside_tree():
			continue
		var dmg := int(area.get("damage")) if area.get("damage") != null else 1
		var is_hazard: bool = area.get("respawn") == true
		if dmg <= 0:
			continue
		var src: Vector2 = area.global_position
		if area.get_parent() is Node2D and not is_hazard:
			src = (area.get_parent() as Node2D).global_position
		take_damage(dmg, src, is_hazard)
		return


func _die() -> void:
	cache_invalidate()
	state = State.DEAD
	_dead_t = 0.0
	velocity = Vector2.ZERO
	Events.camera_shake.emit(24.0, 0.6)
	AudioManager.play_sfx("death")
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(0.1, 0.1, 0.12), 30, 500.0, 1.0, 0.6)


func _hazard_respawn() -> void:
	_hazard_respawning = true
	state = State.LOCKED
	var world := get_tree().get_first_node_in_group("world")
	if world:
		await world.fade_out(0.18)
	place_at(_safe_pos)
	state = State.NORMAL
	_hazard_respawning = false
	if world:
		await world.fade_in(0.18)


func _track_safe_position(delta: float) -> void:
	if not is_on_floor() or state != State.NORMAL:
		return
	_safe_timer += delta
	if _safe_timer < 0.25:
		return
	_safe_timer = 0.0
	var space := get_world_2d().direct_space_state
	for off in [-34.0, 34.0]:
		var from := global_position + Vector2(off, -10)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 40), 1)
		if space.intersect_ray(q).is_empty():
			return
	var pq := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(200, 60)
	pq.shape = shape
	pq.transform = Transform2D(0, global_position + Vector2(0, -10))
	pq.collision_mask = 1 << 6
	pq.collide_with_areas = true
	pq.collide_with_bodies = false
	if space.intersect_shape(pq, 1).is_empty():
		_safe_pos = global_position


func _nearest_interactable() -> Node:
	var best: Node = null
	var best_d := INF
	for area in interact_area.get_overlapping_areas():
		var n: Node = area if area.has_method("interact") else area.get_parent()
		if n and n.has_method("interact") and (not n.has_method("can_interact") or n.can_interact()):
			var d := (area.global_position - global_position).length()
			if d < best_d:
				best_d = d
				best = n
	return best
