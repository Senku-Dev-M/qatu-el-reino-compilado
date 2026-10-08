extends Node
## Estado de la partida en memoria y reglas de progreso.
## Todo lo persistente vive en `data` (serializable a JSON).

const SAVE_VERSION := 2
const HEAL_COST := 0.33
const CHARM_SLOTS := 3
const SHARDS_PER_MASK := 2
const SEMANTICA_TABLILLAS := 6
const LESSON_CHECK_BITS := 5

var data: Dictionary = {}
var slot := 1
## Estado de sesión (no se guarda).
var at_bench := false
var pending_start := {"slot": 1, "new": true}
var play_time_accum := 0.0


func _ready() -> void:
	new_game()


func _process(delta: float) -> void:
	play_time_accum += delta
	if play_time_accum >= 1.0:
		data.play_time += int(play_time_accum)
		play_time_accum = fmod(play_time_accum, 1.0)


func defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"room": "hub_plaza",
		"bench_room": "hub_plaza",
		"bench_id": "banco",
		"bits": 0,
		"masks": 5,
		"masks_max": 5,
		"energy": 0.0,
		"mask_shards": 0,
		"abilities": [],
		"charms_owned": [],
		"charms_equipped": [],
		"armas": ["cursor"],
		"arma": "cursor",
		"vestimenta": "base",
		"tablillas": [],
		"lecciones_ok": [],
		"glosario": [],
		"sellos": [],
		"bestiary": {},
		"rooms_visited": [],
		"flags": {},
		"shade": null,
		"play_time": 0,
	}


func new_game() -> void:
	data = defaults()


# --- Serialización ---------------------------------------------------------

func to_dict() -> Dictionary:
	return data.duplicate(true)


func from_dict(d: Dictionary) -> void:
	var base := defaults()
	for key in base.keys():
		if not d.has(key) or d[key] == null:
			continue
		var def = base[key]
		match typeof(def):
			TYPE_INT:
				base[key] = int(d[key])
			TYPE_FLOAT:
				base[key] = float(d[key])
			TYPE_STRING:
				base[key] = str(d[key])
			TYPE_ARRAY:
				base[key] = Array(d[key]).duplicate()
			TYPE_DICTIONARY:
				base[key] = Dictionary(d[key]).duplicate(true)
	if d.get("shade") is Dictionary:
		var s: Dictionary = d.shade
		base.shade = {"room": str(s.get("room", "")), "x": float(s.get("x", 0)), "y": float(s.get("y", 0)), "bits": int(s.get("bits", 0))}
	var counts := {}
	for k in base.bestiary.keys():
		counts[k] = int(base.bestiary[k])
	base.bestiary = counts
	# v1 usaba tablillas T01..T12; el currículo nuevo usa lecciones L01..
	if int(d.get("version", 1)) < 2:
		base.tablillas = base.tablillas.filter(func(x): return str(x).begins_with("L"))
		base.version = SAVE_VERSION
	if not ("cursor" in base.armas):
		base.armas.push_front("cursor")
	if not (base.arma in base.armas):
		base.arma = "cursor"
	data = base
	if not is_skin_unlocked(str(base.vestimenta)):
		base.vestimenta = "base"
	data = base


func _db() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	return loop.root.get_node_or_null("ContentDB") if loop else null


# --- Economía y vida ---------------------------------------------------------

func add_bits(n: int) -> void:
	data.bits += n
	Events.bits_changed.emit(data.bits)


func spend_bits(n: int) -> bool:
	if data.bits < n:
		return false
	data.bits -= n
	Events.bits_changed.emit(data.bits)
	return true


## Devuelve true si el jugador muere.
func damage(n: int) -> bool:
	data.masks = maxi(0, data.masks - n)
	Events.masks_changed.emit(data.masks, data.masks_max)
	return data.masks == 0


func heal(n: int) -> void:
	data.masks = mini(data.masks_max, data.masks + n)
	Events.masks_changed.emit(data.masks, data.masks_max)


func add_energy(v: float) -> void:
	data.energy = clampf(data.energy + v, 0.0, 1.0)
	Events.energy_changed.emit(data.energy)


func heal_cost() -> float:
	return HEAL_COST * (0.67 if is_charm_equipped("gzip") else 1.0)


func can_heal() -> bool:
	return data.energy >= heal_cost() - 0.0001 and data.masks < data.masks_max


func try_consume_heal() -> bool:
	if data.energy < heal_cost() - 0.0001:
		return false
	data.energy = maxf(0.0, data.energy - heal_cost())
	Events.energy_changed.emit(data.energy)
	return true


func add_shard() -> void:
	data.mask_shards += 1
	if data.mask_shards >= SHARDS_PER_MASK:
		data.mask_shards -= SHARDS_PER_MASK
		data.masks_max += 1
		data.masks = data.masks_max
		Events.notify.emit("¡Nueva máscara! Vida máxima: %d" % data.masks_max)
	else:
		Events.notify.emit("Fragmento de máscara (%d/%d)" % [data.mask_shards, SHARDS_PER_MASK])
	Events.masks_changed.emit(data.masks, data.masks_max)


# --- Muerte y Conflicto de Merge --------------------------------------------

func on_death(room: String, pos: Vector2) -> void:
	if data.bits > 0:
		data.shade = {"room": room, "x": pos.x, "y": pos.y, "bits": data.bits}
	else:
		data.shade = null
	data.bits = 0
	data.energy = 0.0
	data.masks = data.masks_max
	Events.bits_changed.emit(data.bits)
	Events.energy_changed.emit(data.energy)
	Events.masks_changed.emit(data.masks, data.masks_max)


func recover_shade() -> void:
	if data.shade == null:
		return
	add_bits(int(data.shade.bits))
	data.shade = null
	Events.notify.emit("Conflicto resuelto: Bits recuperados")


func rest(room: String, bench_id: String) -> void:
	data.bench_room = room
	data.bench_id = bench_id
	data.masks = data.masks_max
	Events.masks_changed.emit(data.masks, data.masks_max)


# --- Conocimiento ------------------------------------------------------------

func read_tablilla(id: String) -> bool:
	var is_new: bool = not (id in data.tablillas)
	if is_new:
		data.tablillas.append(id)
	Events.tablilla_read.emit(id, is_new)
	if is_new and data.tablillas.size() >= SEMANTICA_TABLILLAS and not ("semantica" in data.charms_owned):
		grant_charm("semantica")
	return is_new


## Marca la comprobación de una lección como superada. Devuelve true la primera vez.
func complete_lesson(id: String) -> bool:
	if id in data.lecciones_ok:
		return false
	data.lecciones_ok.append(id)
	add_bits(LESSON_CHECK_BITS)
	Events.notify.emit("Lección comprobada: +%d Bits" % LESSON_CHECK_BITS)
	return true


func is_lesson_checked(id: String) -> bool:
	return id in data.lecciones_ok


## Añade términos al glosario. Devuelve los nuevos.
func learn_terms(ids: Array) -> Array:
	var added := []
	for t in ids:
		if not (t in data.glosario):
			data.glosario.append(t)
			added.append(t)
	return added


func resolve_sello(id: String) -> void:
	if not (id in data.sellos):
		data.sellos.append(id)
	Events.sello_resolved.emit(id)


func register_kill(enemy_id: String) -> int:
	var n := int(data.bestiary.get(enemy_id, 0)) + 1
	data.bestiary[enemy_id] = n
	Events.enemy_defeated.emit(enemy_id, n)
	return n


func kills(enemy_id: String) -> int:
	return int(data.bestiary.get(enemy_id, 0))


# --- Habilidades y amuletos -------------------------------------------------

func grant_ability(id: String) -> void:
	if not (id in data.abilities):
		data.abilities.append(id)
		Events.ability_granted.emit(id)


func has_ability(id: String) -> bool:
	return id in data.abilities


# --- Vestimentas ------------------------------------------------------------------------

## La base y la de la zona 1 están libres; la de la zona N se desbloquea al vencer
## al jefe de la zona N-1 (campo `requiere_jefe` de content/vestimentas).
func is_skin_unlocked(id: String) -> bool:
	var db := _db()
	if db == null:
		return id == "base"
	var v: Dictionary = db.vestimenta(id)
	if v.is_empty():
		return false
	var jefe := str(v.get("requiere_jefe", ""))
	return jefe == "" or bool(get_flag("jefe:" + jefe))


func set_skin(id: String) -> bool:
	if not is_skin_unlocked(id):
		return false
	data.vestimenta = id
	Events.skin_changed.emit(id)
	return true


## Vestimentas que desbloquea vencer a un jefe (para avisar al jugador).
func skins_unlocked_by(boss_kind: String) -> Array:
	var out := []
	var db := _db()
	if db == null:
		return out
	for v in db.vestimentas_ordenadas():
		if str(v.get("requiere_jefe", "")) == boss_kind:
			out.append(v)
	return out


# --- Armas ------------------------------------------------------------------------------

func has_weapon(id: String) -> bool:
	return id in data.armas


## Añade un arma al inventario y la equipa.
func grant_weapon(id: String) -> void:
	if not (id in data.armas):
		data.armas.append(id)
	equip_weapon(id)


func equip_weapon(id: String) -> bool:
	if not (id in data.armas):
		return false
	data.arma = id
	Events.weapon_changed.emit(id)
	return true


## Siguiente arma del inventario (en orden de zona). Devuelve la equipada.
func cycle_weapon() -> String:
	var owned: Array = []
	var db := _db()
	if db:
		for w in db.armas_ordenadas():
			if w.id in data.armas:
				owned.append(w.id)
	else:
		owned = data.armas.duplicate()
	if owned.size() <= 1:
		return data.arma
	var i := owned.find(data.arma)
	equip_weapon(owned[(i + 1) % owned.size()])
	return data.arma


func grant_charm(id: String) -> void:
	if not (id in data.charms_owned):
		data.charms_owned.append(id)
		Events.charm_granted.emit(id)


func equip_charm(id: String, cost: int) -> bool:
	if not (id in data.charms_owned) or id in data.charms_equipped:
		return false
	if cost > free_slots():
		return false
	data.charms_equipped.append(id)
	Events.charms_changed.emit()
	return true


func charm_cost(id: String) -> int:
	var db := _db()
	if db and db.amuleto(id).has("coste"):
		return int(db.amuleto(id).coste)
	return 1


func unequip_charm(id: String) -> void:
	data.charms_equipped.erase(id)
	Events.charms_changed.emit()


func is_charm_equipped(id: String) -> bool:
	return id in data.charms_equipped


func free_slots() -> int:
	var used := 0
	for c in data.charms_equipped:
		used += charm_cost(c)
	return CHARM_SLOTS - used


# --- Flags y mundo -------------------------------------------------------------

func set_flag(key: String, value: Variant = true) -> void:
	data.flags[key] = value
	Events.flag_changed.emit(key, value)


func get_flag(key: String) -> Variant:
	return data.flags.get(key, false)


func visit_room(id: String) -> void:
	data.room = id
	if not (id in data.rooms_visited):
		data.rooms_visited.append(id)


# --- Progreso ------------------------------------------------------------------

func zone_completion(zone: int) -> float:
	var db := _db()
	if db == null:
		return 0.0
	var total := 0
	var done := 0
	for tab in db.tablillas_de_zona(zone):
		total += 2
		if tab.id in data.tablillas:
			done += 1
		if tab.id in data.lecciones_ok:
			done += 1
	for s in db.sellos_de_zona(zone):
		total += 1
		if s.id in data.sellos:
			done += 1
	for e in db.enemigos_de_zona(zone):
		total += 1
		if kills(e.id) >= int(e.derrotas_requeridas):
			done += 1
	for a in db.amuletos_de_zona(zone):
		total += 1
		if a.id in data.charms_owned:
			done += 1
	# Fragmentos de máscara, habilidad y jefe definidos en zonas.json.
	var z: Dictionary = db.zona(zone)
	for key in z.get("fragmentos", []):
		total += 1
		if get_flag(key):
			done += 1
	if str(z.get("habilidad", "")) != "":
		total += 1
		if has_ability(z.habilidad):
			done += 1
	if str(z.get("jefe", "")) != "":
		total += 1
		if get_flag("jefe:" + str(z.jefe)):
			done += 1
	if total == 0:
		return 0.0
	return 100.0 * done / total
