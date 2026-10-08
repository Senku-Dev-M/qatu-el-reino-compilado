class_name HUD
extends Control
## Orbe de Energía de Compilación, máscaras, Bits y arma equipada.

var energy_shown := 0.0
var masks := 5
var masks_max := 5
var mask_pulse := {}
var bits_label: Label
var weapon_label: Label
var bits_shown := 0
var bits_target := 0
var t := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	bits_label = UITheme.label("0", 34, UITheme.TEXT, true)
	bits_label.position = Vector2(206, 138)
	add_child(bits_label)
	Events.masks_changed.connect(_on_masks)
	Events.bits_changed.connect(func(v): bits_target = v)
	weapon_label = UITheme.label("", 22, UITheme.DIM, true)
	weapon_label.position = Vector2(96, 196)
	add_child(weapon_label)
	Events.weapon_changed.connect(func(_id): _refresh_weapon())
	refresh()


func refresh() -> void:
	masks = GameState.data.masks
	masks_max = GameState.data.masks_max
	bits_target = GameState.data.bits
	bits_shown = bits_target
	energy_shown = GameState.data.energy
	_refresh_weapon()


func _refresh_weapon() -> void:
	if weapon_label == null:
		return
	var w := ContentDB.arma(str(GameState.data.get("arma", "cursor")))
	var extra := "   [%s]" % Settings.key_name("arma") if GameState.data.get("armas", []).size() > 1 else ""
	weapon_label.text = str(w.get("nombre", "Cursor")) + extra


func _on_masks(cur: int, mx: int) -> void:
	for i in range(mini(cur, masks), maxi(cur, masks)):
		mask_pulse[i] = 1.0
	masks = cur
	masks_max = mx


func _process(delta: float) -> void:
	t += delta
	energy_shown = lerpf(energy_shown, GameState.data.energy, 1.0 - exp(-8.0 * delta))
	if bits_shown != bits_target:
		var step := maxi(1, absi(bits_target - bits_shown) / 12)
		bits_shown = move_toward(bits_shown, bits_target, step)
		bits_label.text = str(bits_shown)
	else:
		bits_label.text = str(bits_target)
	for k in mask_pulse.keys():
		mask_pulse[k] = maxf(0.0, mask_pulse[k] - delta * 2.5)
	queue_redraw()


func _draw() -> void:
	# Orbe de energía.
	var c := Vector2(120, 110)
	var r := 62.0
	draw_circle(c, r + 8, Color(0, 0, 0, 0.5))
	draw_circle(c, r, Color(0.02, 0.03, 0.04, 0.9))
	var level := c.y + r - energy_shown * r * 2.0
	if energy_shown > 0.01:
		var poly := PackedVector2Array()
		for i in 21:
			var x := c.x - r - 4 + i * ((r + 4) * 2.0 / 20.0)
			poly.append(Vector2(x, level + sin(t * 3.0 + i * 0.6) * 3.0))
		poly.append(Vector2(c.x + r + 4, c.y + r + 4))
		poly.append(Vector2(c.x - r - 4, c.y + r + 4))
		var clipped := _clip_circle(poly, c, r)
		if clipped.size() > 2:
			draw_colored_polygon(clipped, Color(0.85, 0.95, 0.95, 0.92))
	var full := energy_shown >= GameState.heal_cost()
	draw_arc(c, r, 0, TAU, 64, Color(0.95, 0.95, 0.9) if full else Color(0.6, 0.6, 0.6), 4.0, true)
	draw_arc(c, r + 6, -PI * 0.8, -PI * 0.2, 24, Color(0.9, 0.85, 0.7, 0.6), 2.0, true)
	# Máscaras.
	for i in masks_max:
		var mp := Vector2(222 + i * 58, 80)
		var pulse: float = mask_pulse.get(i, 0.0)
		_draw_mask(mp, i < masks, 1.0 + pulse * 0.35)
	# Arma equipada.
	var wp := Vector2(70, 212)
	var arr: Array = ContentDB.arma(str(GameState.data.get("arma", "cursor"))).get("color", [2.5, 2.6, 2.8])
	if str(GameState.data.get("arma", "cursor")) == "cursor":
		arr = ContentDB.vestimenta(str(GameState.data.get("vestimenta", "base"))).get("espada", arr)
	var wc := Color(minf(float(arr[0]), 1.3), minf(float(arr[1]), 1.3), minf(float(arr[2]), 1.3))
	draw_colored_polygon(PackedVector2Array([wp + Vector2(0, -20), wp + Vector2(20, 0), wp + Vector2(0, 20), wp + Vector2(-20, 0)]), Color(0.02, 0.03, 0.04, 0.9))
	draw_polyline(PackedVector2Array([wp + Vector2(0, -20), wp + Vector2(20, 0), wp + Vector2(0, 20), wp + Vector2(-20, 0), wp + Vector2(0, -20)]), Color(0.9, 0.85, 0.7, 0.7), 2.0)
	draw_line(wp + Vector2(-8, 8), wp + Vector2(8, -8), wc, 3.0)
	draw_line(wp + Vector2(-9, 2), wp + Vector2(-2, 9), Color(0.8, 0.7, 0.5), 2.0)
	# Icono de Bits.
	var bp := Vector2(186, 162)
	draw_colored_polygon(PackedVector2Array([bp + Vector2(0, -12), bp + Vector2(10, 0), bp + Vector2(0, 12), bp + Vector2(-10, 0)]), UITheme.GOLD)
	draw_colored_polygon(PackedVector2Array([bp + Vector2(0, -6), bp + Vector2(5, 0), bp + Vector2(0, 6), bp + Vector2(-5, 0)]), Color(0.1, 0.08, 0.02))


func _clip_circle(poly: PackedVector2Array, c: Vector2, r: float) -> PackedVector2Array:
	var circle := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		circle.append(c + Vector2(cos(a), sin(a)) * r)
	var res := Geometry2D.intersect_polygons(poly, circle)
	return res[0] if res.size() > 0 else PackedVector2Array()


func _draw_mask(p: Vector2, filled: bool, scale: float) -> void:
	var col := Color(0.96, 0.96, 0.94) if filled else Color(0.25, 0.25, 0.27, 0.8)
	var s := scale
	draw_polyline(PackedVector2Array([p + Vector2(-5, -14) * s, p + Vector2(-13, -22) * s, p + Vector2(-6, -30) * s]), col, 3.5, true)
	draw_polyline(PackedVector2Array([p + Vector2(5, -14) * s, p + Vector2(13, -22) * s, p + Vector2(6, -30) * s]), col, 3.5, true)
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(p + Vector2(cos(a) * 15, sin(a) * (16 if sin(a) < 0 else 14)) * s)
	if filled:
		draw_colored_polygon(pts, col)
		draw_circle(p + Vector2(-5, 2) * s, 3 * s, Color(0.02, 0.02, 0.03))
		draw_circle(p + Vector2(5, 2) * s, 3 * s, Color(0.02, 0.02, 0.03))
	else:
		pts.append(pts[0])
		draw_polyline(pts, col, 2.5, true)
