extends Node
## Opciones del jugador: controles, volumen y pantalla.

const PATH := "user://settings.json"

## acción → [teclas por defecto (la primera es remapeable), botones de mando]
const ACTIONS := {
	"move_left": {"label": "Izquierda", "keys": [KEY_LEFT, KEY_A], "joy": [JOY_BUTTON_DPAD_LEFT], "axis": [JOY_AXIS_LEFT_X, -1.0]},
	"move_right": {"label": "Derecha", "keys": [KEY_RIGHT, KEY_D], "joy": [JOY_BUTTON_DPAD_RIGHT], "axis": [JOY_AXIS_LEFT_X, 1.0]},
	"look_up": {"label": "Arriba / Interactuar", "keys": [KEY_UP, KEY_W], "joy": [JOY_BUTTON_DPAD_UP], "axis": [JOY_AXIS_LEFT_Y, -1.0]},
	"look_down": {"label": "Abajo", "keys": [KEY_DOWN, KEY_S], "joy": [JOY_BUTTON_DPAD_DOWN], "axis": [JOY_AXIS_LEFT_Y, 1.0]},
	"jump": {"label": "Saltar", "keys": [KEY_Z, KEY_SPACE], "joy": [JOY_BUTTON_A]},
	"attack": {"label": "Atacar", "keys": [KEY_X, KEY_J], "joy": [JOY_BUTTON_X]},
	"grapple": {"label": "Event Listener", "keys": [KEY_C, KEY_K], "joy": [JOY_BUTTON_RIGHT_SHOULDER]},
	"heal": {"label": "Hotfix (mantener)", "keys": [KEY_F, KEY_L], "joy": [JOY_BUTTON_B]},
	"flex": {"label": "Flex (cambiar valor)", "keys": [KEY_V, KEY_U], "joy": [JOY_BUTTON_LEFT_SHOULDER]},
	"promesa": {"label": "Promesa (activar fuente)", "keys": [KEY_B, KEY_O], "joy": [JOY_BUTTON_LEFT_STICK]},
	"cache": {"label": "Caché (guardar / restaurar)", "keys": [KEY_G, KEY_Y], "joy": [JOY_BUTTON_RIGHT_STICK]},
	"token": {"label": "Token (renovar)", "keys": [KEY_H, KEY_P], "joy": [JOY_BUTTON_DPAD_RIGHT]},
	"dash": {"label": "REST Dash (impulso)", "keys": [KEY_SHIFT, KEY_R], "joy": [], "axis": [JOY_AXIS_TRIGGER_RIGHT, 1.0]},
	"binding": {"label": "Data Binding (enlazar)", "keys": [KEY_T, KEY_N], "joy": [], "axis": [JOY_AXIS_TRIGGER_LEFT, 1.0]},
	"contenedor": {"label": "Contenedor (desplegar Pod)", "keys": [KEY_M, KEY_1], "joy": [JOY_BUTTON_PADDLE1]},
	"inspector": {"label": "Inspector (revelar)", "keys": [KEY_2, KEY_9], "joy": [JOY_BUTTON_PADDLE2]},
	"arma": {"label": "Cambiar de arma", "keys": [KEY_Q, KEY_3], "joy": [JOY_BUTTON_MISC1]},
	"map": {"label": "Mapa", "keys": [KEY_TAB], "joy": [JOY_BUTTON_BACK]},
	"codice": {"label": "Códice", "keys": [KEY_I], "joy": [JOY_BUTTON_Y]},
	"pause": {"label": "Pausa", "keys": [KEY_ESCAPE], "joy": [JOY_BUTTON_START]},
}

var music_volume := 0.7
var sfx_volume := 0.8
var fullscreen := false
var key_overrides := {}


func _ready() -> void:
	_ensure_buses()
	load_settings()
	apply()


func _ensure_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.6
		rev.wet = 0.12
		rev.dry = 1.0
		AudioServer.add_bus_effect(sfx, rev)


func apply() -> void:
	_build_input_map()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_volume, 0.0001)))
	if not DisplayServer.get_name() == "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func _build_input_map() -> void:
	for action in ACTIONS.keys():
		var def: Dictionary = ACTIONS[action]
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.35)
		var keys: Array = def.keys.duplicate()
		if key_overrides.has(action):
			keys[0] = int(key_overrides[action])
		for k in keys:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in def.joy:
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
		if def.has("axis"):
			var ja := InputEventJoypadMotion.new()
			ja.axis = def.axis[0]
			ja.axis_value = def.axis[1]
			InputMap.action_add_event(action, ja)
	# Cambio de pestaña en el Códice.
	for pair in [["tab_prev", KEY_Q, JOY_BUTTON_LEFT_SHOULDER], ["tab_next", KEY_E, JOY_BUTTON_RIGHT_SHOULDER]]:
		if InputMap.has_action(pair[0]):
			InputMap.action_erase_events(pair[0])
		else:
			InputMap.add_action(pair[0])
		var kev := InputEventKey.new()
		kev.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], kev)
		var jev := InputEventJoypadButton.new()
		jev.button_index = pair[2]
		InputMap.action_add_event(pair[0], jev)
	# Confirmar/cancelar en menús también con las teclas del juego.
	for pair in [["ui_accept", KEY_Z], ["ui_accept", KEY_SPACE], ["ui_cancel", KEY_X], ["ui_cancel", KEY_ESCAPE]]:
		var ev := InputEventKey.new()
		ev.physical_keycode = pair[1]
		if not InputMap.action_has_event(pair[0], ev):
			InputMap.action_add_event(pair[0], ev)


func key_for(action: String) -> int:
	if key_overrides.has(action):
		return int(key_overrides[action])
	return ACTIONS[action].keys[0]


const KEY_NAMES := {
	"Up": "↑", "Down": "↓", "Left": "←", "Right": "→", "Space": "Espacio",
	"Escape": "Esc", "Enter": "Intro", "Shift": "Mayús", "Ctrl": "Ctrl", "Tab": "Tab",
}


func key_name(action: String) -> String:
	var raw := OS.get_keycode_string(key_for(action))
	return KEY_NAMES.get(raw, raw)


func set_key(action: String, keycode: int) -> void:
	key_overrides[action] = keycode
	apply()
	save_settings()


func reset_keys() -> void:
	key_overrides.clear()
	apply()
	save_settings()


func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"keys": key_overrides,
	}, "\t"))


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		return
	music_volume = float(d.get("music_volume", music_volume))
	sfx_volume = float(d.get("sfx_volume", sfx_volume))
	fullscreen = bool(d.get("fullscreen", fullscreen))
	var keys = d.get("keys", {})
	if keys is Dictionary:
		for k in keys.keys():
			if ACTIONS.has(k):
				key_overrides[k] = int(keys[k])
