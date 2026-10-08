extends Node2D
## Autorizador: servidor de autorización que emite un access token con un
## alcance y una caducidad, además del refresh token.
##
## Definición: {"type": "autorizador", "scope": "lector" | "vendedor" | "admin",
##              "ttl": segundos (0 = el del jugador), "refresh": bool,
##              "etiqueta": texto de la pantalla}

var room: RoomBase
var def: Dictionary
var t := 0.0
var flash := 0.0
var it: Interactable


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	it = Interactable.new()
	add_child(it)
	it.setup(Vector2(130, 160), Vector2(0, -80), "Pedir token (%s)" % scope())
	var light := FX.make_light(Color(1.0, 0.85, 0.5), 2.2, 0.9)
	light.position = Vector2(0, -80)
	add_child(light)


func scope() -> String:
	return str(def.get("scope", "lector"))


func interact(p: Player) -> void:
	if not GameState.has_ability("token"):
		Events.notify.emit("La consola no te reconoce. Necesitas la habilidad Tokens.")
		AudioManager.play_sfx("sello_bad")
		return
	p.grant_token(scope(), float(def.get("ttl", 0.0)), bool(def.get("refresh", true)))
	flash = 1.0
	Events.notify.emit("access_token · scope: %s · expira en %d s" % [scope(), ceili(p.token_ttl)])


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var stone := Color(0.16, 0.15, 0.22)
	var gold := Color(2.4, 1.9, 0.8)
	# Pedestal con pantalla.
	draw_colored_polygon(PackedVector2Array([Vector2(-40, 0), Vector2(40, 0), Vector2(30, -26), Vector2(-30, -26)]), stone)
	var screen := Rect2(-42, -118, 84, 92)
	draw_rect(screen, Color(0.05, 0.05, 0.09))
	draw_rect(screen, Color(gold, 0.7 + 0.3 * flash), false, 2.0)
	# Sello giratorio de identidad.
	var c := screen.get_center()
	for i in 3:
		var a := t * (0.8 + i * 0.4)
		draw_arc(c, 14.0 + i * 8.0, a, a + PI * 1.2, 20, Color(gold, 0.5 - i * 0.12), 2.0, true)
	draw_circle(c, 7, gold.lerp(Color(3, 3, 3), flash))
	var font := UITheme.mono_font()
	var label := str(def.get("etiqueta", "/authorize"))
	var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, Vector2(-ts.x * 0.5, -132), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.6, 1.4, 0.9, 0.9))
	var sc := "scope: " + scope()
	var ss := font.get_string_size(sc, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(font, Vector2(-ss.x * 0.5, -6), sc, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(gold, 0.85))
