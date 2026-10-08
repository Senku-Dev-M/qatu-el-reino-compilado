class_name Backdrop
extends Node2D
## Fondo con capas de parallax pintadas proceduralmente según el estilo.

const VIEW := Vector2(1920, 1080)

var th: Dictionary
var room_size: Vector2
var seed_value := 0


func build(p_theme: Dictionary, p_room_size: Vector2, p_seed: int) -> void:
	th = p_theme
	room_size = p_room_size
	seed_value = p_seed
	var layers: Array = [
		{"scale": 0.08, "painter": "_paint_far_light", "z": -100},
		{"scale": 0.2, "painter": "_paint_far", "z": -90},
		{"scale": 0.45, "painter": "_paint_mid", "z": -80},
		{"scale": 0.72, "painter": "_paint_near", "z": -70},
		{"scale": 1.0, "painter": "_paint_fog", "z": -60},
	]
	for i in layers.size():
		var def: Dictionary = layers[i]
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(def.scale, def.scale)
		px.z_index = def.z
		px.ignore_camera_scroll = false
		add_child(px)
		var painter := Node2D.new()
		px.add_child(painter)
		var extent := _extent(def.scale)
		var method: String = def.painter
		var layer_seed := seed_value + i * 7919
		painter.draw.connect(func(): call(method, painter, extent, layer_seed))
		painter.queue_redraw()


func _extent(scale: float) -> Rect2:
	var size := Vector2(
		maxf(0.0, room_size.x - VIEW.x) * scale + VIEW.x,
		maxf(0.0, room_size.y - VIEW.y) * scale + VIEW.y)
	return Rect2(Vector2(-300, -300), size + Vector2(600, 600))


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


# --- Capas comunes -------------------------------------------------------------

func _paint_far_light(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var tex := FX.light_texture()
	var accent: Color = th.glow
	if th.style == "hub":
		accent = Color(1.2, 1.1, 1.3)
	elif th.style == "river":
		accent = Color(0.4, 1.0, 1.5)
	elif th.style == "archive":
		accent = Color(1.4, 1.0, 0.6) if not th.get("vault", false) else Color(0.6, 0.8, 1.6)
	elif th.style == "citadel":
		accent = Color(1.0, 0.9, 1.6)
	for i in 5:
		var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y * 0.7))
		var sz := r.randf_range(700, 1400)
		c.draw_texture_rect(tex, Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(accent, 0.07))
	if th.style == "canyon":
		_canyon_sky(c, e, r)
	elif th.style == "river":
		_river_sky(c, e, r)
	elif th.style == "archive":
		_archive_sky(c, e, r)
	elif th.style == "citadel":
		_citadel_sky(c, e, r)
	elif th.style == "hub":
		# Luna y estrellas.
		var moon := Vector2(e.position.x + e.size.x * 0.72, e.position.y + 380)
		c.draw_texture_rect(tex, Rect2(moon - Vector2(500, 500), Vector2(1000, 1000)), false, Color(0.8, 0.8, 1.0, 0.18))
		c.draw_circle(moon, 70, Color(1.5, 1.45, 1.3))
		c.draw_circle(moon + Vector2(18, -10), 62, Color(0.12, 0.1, 0.16, 0.25))
		for i in 160:
			var sp := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.position.y + e.size.y * 0.55))
			c.draw_circle(sp, r.randf_range(0.8, 2.2), Color(1.3, 1.3, 1.5, r.randf_range(0.2, 0.9)))
	else:
		# Haces de luz diagonales.
		for i in 6:
			var x := r.randf_range(e.position.x, e.end.x)
			var wdt := r.randf_range(60, 220)
			var poly := PackedVector2Array([
				Vector2(x, e.position.y), Vector2(x + wdt, e.position.y),
				Vector2(x + wdt + 600, e.end.y), Vector2(x + 600, e.end.y)])
			c.draw_colored_polygon(poly, Color(th.glow, 0.01))


func _paint_fog(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var tex := FX.light_texture()
	var fog: Color = th.fog
	var count := int(e.size.x * e.size.y / 250000.0)
	for i in count:
		var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
		var sz := Vector2(r.randf_range(600, 1300), r.randf_range(180, 360))
		c.draw_texture_rect(tex, Rect2(p - sz * 0.5, sz), false, fog)


func _paint_far(c: CanvasItem, e: Rect2, s: int) -> void:
	match th.style:
		"hub": _hub_mountains(c, e, s)
		"cave": _cave_far(c, e, s)
		"engine": _engine_far(c, e, s)
		"canyon": _canyon_mesas(c, e, s)
		"river": _river_far(c, e, s)
		"archive": _archive_far(c, e, s)
		"citadel": _citadel_far(c, e, s)
		"arena": _forest_far(c, e, s, true)
		_: _forest_far(c, e, s, false)


func _paint_mid(c: CanvasItem, e: Rect2, s: int) -> void:
	match th.style:
		"hub": _hub_city(c, e, s)
		"cave": _cave_crystals(c, e, s, th.mid, 1.0)
		"engine": _engine_gears(c, e, s, th.mid, 1.0)
		"canyon": _canyon_walls(c, e, s)
		"river": _river_mid(c, e, s)
		"archive": _archive_mid(c, e, s)
		"citadel": _citadel_mid(c, e, s)
		_: _forest_trunks(c, e, s, th.mid, 0.9)


func _paint_near(c: CanvasItem, e: Rect2, s: int) -> void:
	match th.style:
		"hub": _hub_ruins(c, e, s)
		"cave": _cave_crystals(c, e, s, th.near, 1.6)
		"engine": _engine_gears(c, e, s, th.near, 1.7)
		"canyon": _canyon_near(c, e, s)
		"river": _river_near(c, e, s)
		"archive": _archive_near(c, e, s)
		"citadel": _citadel_near(c, e, s)
		_: _forest_trunks(c, e, s, th.near, 1.5)


# --- Bosque del DOM --------------------------------------------------------------

func _forest_far(c: CanvasItem, e: Rect2, s: int, corrupted: bool) -> void:
	var r := _rng(s)
	var far: Color = th.far
	var node_col: Color = th.glow
	# Troncos lejanos gigantes.
	var x := e.position.x
	while x < e.end.x:
		var wdt := r.randf_range(90, 200)
		_trunk(c, Vector2(x, e.end.y), wdt, e.size.y + 200, far, r)
		x += r.randf_range(380, 700)
	# Árbol DOM en el fondo: nodos conectados.
	var roots := int(e.size.x / 1800.0) + 1
	for i in roots:
		var root := Vector2(e.position.x + (i + 0.5) * e.size.x / roots + r.randf_range(-150, 150), e.position.y + r.randf_range(250, 500))
		_dom_tree(c, root, 4, 420.0, r, node_col, corrupted)


func _dom_tree(c: CanvasItem, p: Vector2, depth: int, spread: float, r: RandomNumberGenerator, col: Color, corrupted: bool) -> void:
	var kids := r.randi_range(2, 3) if depth > 1 else 0
	for k in kids:
		var child := p + Vector2((k - (kids - 1) * 0.5) * spread + r.randf_range(-40, 40), r.randf_range(170, 240))
		c.draw_line(p, child, Color(col, 0.045), 2.0, true)
		_dom_tree(c, child, depth - 1, spread * 0.48, r, col, corrupted)
	var rad := 4.0 + depth * 1.8
	var node_color := col if not (corrupted and r.randf() < 0.3) else Color(2.4, 0.3, 1.8)
	c.draw_circle(p, rad * 3.0, Color(node_color, 0.025))
	c.draw_circle(p, rad, Color(node_color, 0.16))


func _trunk(c: CanvasItem, base: Vector2, wdt: float, height: float, col: Color, r: RandomNumberGenerator) -> void:
	var top := base.y - height
	var lean := r.randf_range(-60, 60)
	var pts := PackedVector2Array()
	var steps := 10
	for i in steps + 1:
		var t := float(i) / steps
		var hw := wdt * 0.5 * (1.0 + (1.0 - t) * 0.6) + sin(t * 9.0 + wdt) * 6.0
		pts.append(Vector2(base.x + lean * t - hw, base.y - t * height))
	for i in range(steps, -1, -1):
		var t := float(i) / steps
		var hw := wdt * 0.5 * (1.0 + (1.0 - t) * 0.6) + cos(t * 7.0 + wdt) * 6.0
		pts.append(Vector2(base.x + lean * t + hw, base.y - t * height))
	c.draw_colored_polygon(pts, col)
	# Raíces en la base.
	for k in 3:
		var dir := -1.0 if k % 2 == 0 else 1.0
		var root := PackedVector2Array([
			Vector2(base.x + dir * wdt * 0.3, base.y - 120),
			Vector2(base.x + dir * wdt * 1.1, base.y - 20),
			Vector2(base.x + dir * wdt * (1.4 + k * 0.3), base.y + 10)])
		c.draw_polyline(root, col, wdt * 0.18, true)


func _forest_trunks(c: CanvasItem, e: Rect2, s: int, col: Color, size_k: float) -> void:
	var r := _rng(s)
	var x := e.position.x + r.randf_range(0, 300)
	while x < e.end.x:
		var wdt := r.randf_range(50, 120) * size_k
		_trunk(c, Vector2(x, e.end.y), wdt, e.size.y + 300, col, r)
		# Enredaderas.
		for v in r.randi_range(1, 3):
			var vy := r.randf_range(e.position.y, e.end.y - 300)
			var vx := x + r.randf_range(-wdt, wdt)
			var length := r.randf_range(150, 500)
			var vine := PackedVector2Array()
			for k in 12:
				var t := k / 11.0
				vine.append(Vector2(vx + sin(t * 5.0 + vy) * 22.0, vy + t * length))
			c.draw_polyline(vine, col, 3.0 * size_k, true)
			if r.randf() < 0.5:
				c.draw_circle(vine[11], 3.5, Color(th.glow, 0.5))
		# Ramas con hojas.
		for b in r.randi_range(1, 3):
			var by := r.randf_range(e.position.y + 100, e.end.y - 200)
			var dir := -1.0 if r.randf() < 0.5 else 1.0
			var tip := Vector2(x + dir * r.randf_range(160, 380) * size_k, by - r.randf_range(40, 140))
			c.draw_polyline(PackedVector2Array([Vector2(x, by), (Vector2(x, by) + tip) * 0.5 + Vector2(0, 30), tip]), col, 14.0 * size_k, true)
			for l in 6:
				var lp := tip + Vector2(r.randf_range(-90, 90), r.randf_range(-50, 30)) * size_k
				_leaf_cluster(c, lp, r.randf_range(30, 60) * size_k, col, r)
		x += r.randf_range(300, 650) * size_k


func _leaf_cluster(c: CanvasItem, p: Vector2, rad: float, col: Color, r: RandomNumberGenerator) -> void:
	for i in 5:
		var off := Vector2(r.randf_range(-rad, rad), r.randf_range(-rad * 0.5, rad * 0.5))
		var pts := PackedVector2Array()
		var rr := rad * r.randf_range(0.4, 0.8)
		for k in 10:
			var a := TAU * k / 10.0
			pts.append(p + off + Vector2(cos(a) * rr * 1.4, sin(a) * rr * 0.7))
		c.draw_colored_polygon(pts, col)


# --- Plaza de Qatu (hub) --------------------------------------------------------

func _hub_mountains(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	for layer in 2:
		var col: Color = th.far.lerp(th.sky_bottom, 0.35 - layer * 0.35)
		var base_y := e.position.y + e.size.y * (0.55 + layer * 0.08)
		var pts := PackedVector2Array([Vector2(e.position.x, e.end.y)])
		var x := e.position.x
		while x <= e.end.x + 200:
			pts.append(Vector2(x, base_y - r.randf_range(80, 420 - layer * 120)))
			x += r.randf_range(120, 260)
		pts.append(Vector2(x, e.end.y))
		c.draw_colored_polygon(pts, col)
		if layer == 0:
			# Nieve en las cumbres.
			for i in range(1, pts.size() - 1):
				var p: Vector2 = pts[i]
				if p.y < base_y - 300:
					c.draw_colored_polygon(PackedVector2Array([p, p + Vector2(-40, 50), p + Vector2(-10, 40), p + Vector2(15, 55), p + Vector2(40, 50)]), Color(0.5, 0.5, 0.6, 0.35))


func _hub_city(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.mid
	var ground := e.end.y - 250
	var x := e.position.x
	while x < e.end.x:
		var bw := r.randf_range(160, 340)
		var bh := r.randf_range(220, 620)
		# Edificio escalonado andino.
		var steps := r.randi_range(2, 4)
		for k in steps:
			var inset := k * bw * 0.12
			var sh := bh / steps
			c.draw_rect(Rect2(x + inset, ground - sh * (k + 1), bw - inset * 2, sh + 2), col)
		# Ventanas y puertas trapezoidales con luz cálida.
		for k in r.randi_range(1, 4):
			var wx := x + r.randf_range(30, bw - 60)
			var wy := ground - r.randf_range(60, bh * 0.8)
			var lit := r.randf() < 0.35
			var wc := Color(2.0, 1.3, 0.5, 0.8) if lit else Color(0.02, 0.02, 0.04)
			c.draw_colored_polygon(PackedVector2Array([Vector2(wx + 6, wy), Vector2(wx + 22, wy), Vector2(wx + 28, wy + 36), Vector2(wx, wy + 36)]), wc)
			if lit:
				c.draw_circle(Vector2(wx + 14, wy + 18), 40, Color(1.5, 0.9, 0.3, 0.06))
		x += bw + r.randf_range(20, 90)
	c.draw_rect(Rect2(e.position.x, ground, e.size.x, e.end.y - ground), col)


func _hub_ruins(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.near
	var ground := e.end.y - 120
	var x := e.position.x
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		if kind == 0:
			_andean_arch(c, Vector2(x, ground), r.randf_range(260, 380), r.randf_range(320, 480), col)
			x += 520
		elif kind == 1:
			_stall(c, Vector2(x, ground), r)
			x += 420
		else:
			# Estandarte tejido colgante.
			var bx := x + 60
			var top := ground - r.randf_range(420, 620)
			c.draw_line(Vector2(bx - 70, top), Vector2(bx + 70, top), col, 8.0)
			c.draw_rect(Rect2(bx - 8, top, 16, ground - top), col)
			_woven_banner(c, Rect2(bx - 55, top + 10, 110, r.randf_range(180, 260)), r)
			x += 300
	c.draw_rect(Rect2(e.position.x, ground, e.size.x, e.end.y - ground), col)


func _andean_arch(c: CanvasItem, base: Vector2, wdt: float, hgt: float, col: Color) -> void:
	var t := wdt * 0.22
	c.draw_rect(Rect2(base.x, base.y - hgt, t, hgt), col)
	c.draw_rect(Rect2(base.x + wdt - t, base.y - hgt, t, hgt), col)
	# Dintel escalonado (chakana).
	for k in 3:
		var inset := k * 26.0
		c.draw_rect(Rect2(base.x - 20 + inset, base.y - hgt - 40 - k * 36, wdt + 40 - inset * 2, 40), col)
	# Grieta de luz.
	c.draw_line(Vector2(base.x + t * 0.5, base.y - hgt * 0.6), Vector2(base.x + t * 0.3, base.y - hgt * 0.3), Color(1.2, 0.8, 0.4, 0.15), 2.0)


func _stall(c: CanvasItem, base: Vector2, r: RandomNumberGenerator) -> void:
	var col: Color = th.near
	var wdt := r.randf_range(220, 320)
	var hgt := r.randf_range(200, 280)
	c.draw_rect(Rect2(base.x, base.y - hgt, 12, hgt), col)
	c.draw_rect(Rect2(base.x + wdt, base.y - hgt, 12, hgt), col)
	c.draw_rect(Rect2(base.x - 10, base.y - 90, wdt + 30, 22), col)
	# Toldo rasgado.
	var aw := PackedVector2Array([Vector2(base.x - 30, base.y - hgt), Vector2(base.x + wdt + 40, base.y - hgt)])
	var px := base.x + wdt + 40
	while px > base.x - 30:
		aw.append(Vector2(px, base.y - hgt + r.randf_range(40, 110)))
		px -= r.randf_range(24, 50)
	aw.append(Vector2(base.x - 30, base.y - hgt + 60))
	c.draw_colored_polygon(aw, Color(0.22, 0.08, 0.07))
	c.draw_polyline(PackedVector2Array([aw[0], aw[1]]), Color(0.5, 0.35, 0.15), 4.0)


func _woven_banner(c: CanvasItem, rect: Rect2, r: RandomNumberGenerator) -> void:
	var palette := [Color(0.35, 0.1, 0.08), Color(0.45, 0.3, 0.08), Color(0.1, 0.2, 0.25), Color(0.25, 0.08, 0.2)]
	var y := rect.position.y
	var i := 0
	while y < rect.end.y:
		var bh := r.randf_range(14, 30)
		var col: Color = palette[i % palette.size()]
		c.draw_rect(Rect2(rect.position.x, y, rect.size.x, bh), col)
		# Zigzag andino.
		var zz := PackedVector2Array()
		var zx := rect.position.x
		var up := true
		while zx <= rect.end.x:
			zz.append(Vector2(zx, y + (2.0 if up else bh - 2.0)))
			zx += 11.0
			up = not up
		c.draw_polyline(zz, Color(col.lightened(0.35), 0.9), 2.0)
		y += bh
		i += 1
	# Borde inferior deshilachado.
	var fr := rect.position.x
	while fr < rect.end.x:
		c.draw_line(Vector2(fr, rect.end.y), Vector2(fr + r.randf_range(-3, 3), rect.end.y + r.randf_range(6, 22)), palette[0], 2.0)
		fr += 7.0


# --- Cueva DevTools ---------------------------------------------------------------

func _cave_far(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	# Retícula del inspector.
	var gstep := 120.0
	var gx := e.position.x
	while gx < e.end.x:
		c.draw_line(Vector2(gx, e.position.y), Vector2(gx, e.end.y), Color(th.glow, 0.012), 1.0)
		gx += gstep
	var gy := e.position.y
	while gy < e.end.y:
		c.draw_line(Vector2(e.position.x, gy), Vector2(e.end.x, gy), Color(th.glow, 0.012), 1.0)
		gy += gstep
	var font := ThemeDB.fallback_font
	var glyphs := ["</>", "{ }", "console.log()", "div", "::before", "debugger;", "#app", "0 errors", "<body>", "margin: auto"]
	for i in int(e.size.x / 160.0):
		var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
		c.draw_string(font, p, glyphs[r.randi() % glyphs.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, r.randi_range(18, 40), Color(th.glow, r.randf_range(0.02, 0.05)))
	_cave_crystals(c, e, s + 3, th.far, 0.8)


func _cave_crystals(c: CanvasItem, e: Rect2, s: int, col: Color, size_k: float) -> void:
	var r := _rng(s)
	var x := e.position.x
	while x < e.end.x:
		var from_top := r.randf() < 0.5
		var base_y := e.position.y + 200 if from_top else e.end.y - 100
		for k in r.randi_range(2, 4):
			var cw := r.randf_range(30, 80) * size_k
			var ch := r.randf_range(150, 450) * size_k
			var cx := x + k * cw * 0.8
			var dir := 1.0 if from_top else -1.0
			var tip := Vector2(cx + r.randf_range(-40, 40), base_y + dir * ch)
			var poly := PackedVector2Array([Vector2(cx - cw * 0.5, base_y - dir * 200), Vector2(cx + cw * 0.5, base_y - dir * 200), tip])
			c.draw_colored_polygon(poly, col)
			c.draw_line(Vector2(cx, base_y), tip, Color(th.glow, 0.12 * size_k), 2.0, true)
		x += r.randf_range(260, 520) * size_k


# --- Cámara del Motor -------------------------------------------------------------

func _engine_far(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	for i in 14:
		var y := r.randf_range(e.position.y, e.end.y)
		var pts := PackedVector2Array()
		var x := e.position.x
		while x < e.end.x:
			pts.append(Vector2(x, y))
			x += r.randf_range(100, 300)
			if r.randf() < 0.4:
				y += r.randf_range(-120, 120)
				pts.append(Vector2(x, y))
		c.draw_polyline(pts, Color(th.far, 1.0), 10.0)
		c.draw_polyline(pts, Color(th.glow, 0.08), 3.0)
	_engine_gears(c, e, s + 5, th.far, 1.3)


func _engine_gears(c: CanvasItem, e: Rect2, s: int, col: Color, size_k: float) -> void:
	var r := _rng(s)
	for i in int(e.size.x * e.size.y / 500000.0) + 2:
		var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
		var rad := r.randf_range(60, 180) * size_k
		var teeth := int(rad / 14.0)
		var pts := PackedVector2Array()
		for k in teeth * 4:
			var a := TAU * k / (teeth * 4)
			var rr := rad if (k % 4) < 2 else rad * 0.84
			pts.append(p + Vector2(cos(a), sin(a)) * rr)
		c.draw_colored_polygon(pts, col)
		c.draw_circle(p, rad * 0.35, th.rock_deep)
		c.draw_arc(p, rad * 0.55, 0, TAU, 32, Color(th.glow, 0.06), 3.0)


# --- Ciudadela IAM --------------------------------------------------------------------

func _citadel_sky(c: CanvasItem, e: Rect2, r: RandomNumberGenerator) -> void:
	var tex := FX.light_texture()
	var idp: bool = th.get("idp", false)
	if idp:
		# Sala del proveedor de identidad: anillos holográficos.
		var core := Vector2(e.position.x + e.size.x * 0.5, e.position.y + e.size.y * 0.4)
		c.draw_texture_rect(tex, Rect2(core - Vector2(700, 700), Vector2(1400, 1400)), false, Color(0.7, 0.8, 2.0, 0.1))
		for i in 6:
			c.draw_arc(core, 150.0 + i * 90.0, 0, TAU, 64, Color(0.8, 1.0, 2.4, 0.08 - i * 0.01), 3.0, true)
		for i in 120:
			var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
			c.draw_circle(p, r.randf_range(1.0, 2.4), Color(1.0, 1.4, 2.6, r.randf_range(0.15, 0.6)))
	else:
		# Cielo nocturno con reflectores desde las torres.
		for i in 150:
			var sp := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.position.y + e.size.y * 0.7))
			c.draw_circle(sp, r.randf_range(0.8, 2.0), Color(1.2, 1.2, 1.6, r.randf_range(0.2, 0.8)))
		for i in int(e.size.x / 1100.0) + 1:
			var base := Vector2(e.position.x + r.randf_range(0, e.size.x), e.end.y)
			var ang := r.randf_range(-0.7, 0.7)
			var tip := base + Vector2(sin(ang), -1.0) * e.size.y
			var w := 120.0
			c.draw_colored_polygon(PackedVector2Array([base + Vector2(-20, 0), base + Vector2(20, 0), tip + Vector2(w, 0), tip + Vector2(-w, 0)]), Color(1.6, 1.4, 0.9, 0.025))
			c.draw_circle(base + Vector2(0, -10), 10, Color(th.glow, 0.25))


func _citadel_far(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.far
	var base_y := e.end.y
	# Perfil de murallas con torres y almenas.
	var x := e.position.x - 80
	while x < e.end.x:
		var w := r.randf_range(260, 460)
		var h := r.randf_range(220, 420)
		c.draw_rect(Rect2(x, base_y - h, w, h), col)
		# Almenas.
		var bx := x
		while bx < x + w - 20:
			c.draw_rect(Rect2(bx, base_y - h - 22, 26, 24), col)
			bx += 48
		# Torre.
		if r.randf() < 0.6:
			var tw := r.randf_range(80, 130)
			var th_ := h + r.randf_range(120, 260)
			var tx := x + r.randf_range(20, maxf(20.0, w - tw - 20))
			c.draw_rect(Rect2(tx, base_y - th_, tw, th_), col.lightened(0.05))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(tx - 12, base_y - th_), Vector2(tx + tw + 12, base_y - th_), Vector2(tx + tw * 0.5, base_y - th_ - 70)]), col.lightened(0.08))
			c.draw_circle(Vector2(tx + tw * 0.5, base_y - th_ + 40), 7, Color(th.glow, 0.3))
		x += w + r.randf_range(40, 160)


func _citadel_mid(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.mid
	var x := e.position.x + r.randf_range(-100, 100)
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		if kind == 0:
			# Arco de puerta con rastrillo.
			var w := r.randf_range(200, 300)
			var h := r.randf_range(320, 520)
			var top := e.end.y - h
			c.draw_rect(Rect2(x, top, 46, h), col)
			c.draw_rect(Rect2(x + w - 46, top, 46, h), col)
			c.draw_rect(Rect2(x - 10, top - 26, w + 20, 32), col)
			var pts := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				pts.append(Vector2(x + w * 0.5 + cos(a) * (w * 0.5 - 40), top + 120 + sin(a) * 90))
			c.draw_polyline(pts, Color(col.lightened(0.08), 1.0), 8.0, true)
			for k in 5:
				c.draw_line(Vector2(x + 50 + k * (w - 110) / 4.0, top + 40), Vector2(x + 50 + k * (w - 110) / 4.0, top + 150), Color(col.lightened(0.05), 1.0), 4.0)
			x += w + r.randf_range(240, 520)
		elif kind == 1:
			# Estandarte con sello de identidad.
			var bw := r.randf_range(70, 110)
			var bh := r.randf_range(220, 340)
			var top := e.position.y + r.randf_range(e.size.y * 0.2, e.size.y * 0.45)
			c.draw_rect(Rect2(x, top, bw, bh), col.lightened(0.06))
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, top + bh), Vector2(x + bw, top + bh), Vector2(x + bw * 0.5, top + bh + 36)]), col.lightened(0.06))
			c.draw_arc(Vector2(x + bw * 0.5, top + bh * 0.45), bw * 0.26, 0, TAU, 24, Color(th.rim, 0.16), 3.0, true)
			x += r.randf_range(320, 620)
		else:
			# Muro con saeteras.
			var w := r.randf_range(300, 520)
			var top := e.position.y + r.randf_range(e.size.y * 0.4, e.size.y * 0.6)
			c.draw_rect(Rect2(x, top, w, e.end.y - top), col)
			var sx := x + 40
			while sx < x + w - 30:
				c.draw_rect(Rect2(sx, top + 60, 10, 46), Color(0, 0, 0, 0.35))
				sx += 90
			x += w + r.randf_range(200, 420)


func _citadel_near(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.near
	var x := e.position.x + r.randf_range(0, 200)
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		var base := e.end.y
		if kind == 0:
			# Poste con farol y sello.
			c.draw_rect(Rect2(x - 6, base - 360, 12, 360), col)
			c.draw_rect(Rect2(x - 26, base - 392, 52, 34), col)
			c.draw_circle(Vector2(x, base - 375), 9, Color(th.glow, 0.4))
			x += r.randf_range(380, 700)
		elif kind == 1:
			# Barrera de control.
			c.draw_rect(Rect2(x, base - 120, 18, 120), col)
			c.draw_rect(Rect2(x + 10, base - 116, 190, 14), col.lightened(0.08))
			for k in 4:
				c.draw_rect(Rect2(x + 20 + k * 46, base - 116, 22, 14), Color(0, 0, 0, 0.3))
			x += r.randf_range(420, 760)
		else:
			# Contrafuerte.
			var w := r.randf_range(120, 220)
			var h := r.randf_range(260, 480)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(x, base), Vector2(x, base - h), Vector2(x + w * 0.5, base - h - 40), Vector2(x + w, base - h), Vector2(x + w, base)]), col)
			x += w + r.randf_range(300, 620)


# --- Archivo Paginado -----------------------------------------------------------------

func _archive_sky(c: CanvasItem, e: Rect2, r: RandomNumberGenerator) -> void:
	var tex := FX.light_texture()
	var vault: bool = th.get("vault", false)
	# Ventanales altos con luz polvorienta.
	for i in int(e.size.x / 900.0) + 1:
		var x := e.position.x + 200 + i * 900 + r.randf_range(-80, 80)
		var top := e.position.y + 120
		var win := Rect2(x, top, 120, 420)
		c.draw_rect(win, Color(0.8, 0.6, 0.35, 0.05) if not vault else Color(0.4, 0.5, 1.0, 0.03))
		c.draw_line(Vector2(x + 60, top), Vector2(x + 60, top + 420), Color(0, 0, 0, 0.25), 6.0)
		c.draw_line(Vector2(x, top + 210), Vector2(x + 120, top + 210), Color(0, 0, 0, 0.25), 6.0)
		var beam := PackedVector2Array([Vector2(x, top), Vector2(x + 120, top), Vector2(x + 620, e.end.y), Vector2(x + 320, e.end.y)])
		c.draw_colored_polygon(beam, Color(1.2, 0.9, 0.5, 0.025) if not vault else Color(0.45, 0.55, 1.0, 0.01))
	# Motas de polvo o cristales de caché.
	for i in 180:
		var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
		c.draw_circle(p, r.randf_range(0.8, 2.2), Color(1.6, 1.3, 0.8, r.randf_range(0.1, 0.5)) if not vault else Color(0.9, 1.4, 2.4, r.randf_range(0.1, 0.5)))
	if vault:
		for i in 6:
			var p := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.position.y + e.size.y * 0.6))
			c.draw_texture_rect(tex, Rect2(p - Vector2(400, 400), Vector2(800, 800)), false, Color(0.5, 0.6, 1.6, 0.06))


func _archive_far(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.far
	# Estanterías gigantes que suben hasta perderse.
	var x := e.position.x - 60
	while x < e.end.x:
		var w := r.randf_range(220, 360)
		c.draw_rect(Rect2(x, e.position.y, w, e.size.y), col)
		var shelf_y := e.position.y + r.randf_range(20, 80)
		while shelf_y < e.end.y:
			c.draw_rect(Rect2(x, shelf_y, w, 8), col.lightened(0.12))
			var bx := x + 6
			while bx < x + w - 10:
				var bw := r.randf_range(8, 18)
				var bh := r.randf_range(40, 70)
				c.draw_rect(Rect2(bx, shelf_y - bh, bw, bh), col.lightened(r.randf_range(0.02, 0.1)))
				bx += bw + r.randf_range(1, 4)
			shelf_y += r.randf_range(90, 120)
		x += w + r.randf_range(60, 160)


func _archive_mid(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.mid
	var x := e.position.x + r.randf_range(-100, 100)
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		if kind == 0:
			# Fichero de cajones con etiquetas.
			var w := r.randf_range(180, 260)
			var top := e.position.y + r.randf_range(e.size.y * 0.35, e.size.y * 0.6)
			c.draw_rect(Rect2(x, top, w, e.end.y - top), col)
			var dy := top + 16
			while dy < e.end.y - 30:
				for k in 3:
					var dw := (w - 24) / 3.0
					var dr := Rect2(x + 6 + k * (dw + 6), dy, dw, 40)
					c.draw_rect(dr, col.lightened(0.08))
					c.draw_rect(Rect2(dr.get_center() - Vector2(10, 4), Vector2(20, 8)), Color(th.rim, 0.12))
				dy += 52
			x += w + r.randf_range(200, 420)
		elif kind == 1:
			# Escalera de mano apoyada.
			var h := r.randf_range(500, 900)
			var base := e.end.y
			c.draw_line(Vector2(x, base), Vector2(x + 120, base - h), col.lightened(0.05), 8.0)
			c.draw_line(Vector2(x + 60, base), Vector2(x + 180, base - h), col.lightened(0.05), 8.0)
			var k := 0.0
			while k < 1.0:
				c.draw_line(Vector2(x + 120 * k, base - h * k), Vector2(x + 60 + 120 * k, base - h * k), col.lightened(0.05), 5.0)
				k += 0.07
			x += r.randf_range(300, 600)
		else:
			# Columna con arco.
			var w := r.randf_range(90, 140)
			c.draw_rect(Rect2(x, e.position.y, w, e.size.y), col)
			c.draw_rect(Rect2(x - 20, e.position.y + e.size.y * 0.3, w + 40, 26), col.lightened(0.05))
			x += w + r.randf_range(300, 600)


func _archive_near(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.near
	var x := e.position.x + r.randf_range(0, 200)
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		var base := e.end.y
		if kind == 0:
			# Pila de libros.
			var y := base
			for k in r.randi_range(6, 12):
				var bw := r.randf_range(90, 150)
				var bh := r.randf_range(22, 40)
				c.draw_rect(Rect2(x - bw * 0.5 + r.randf_range(-12, 12), y - bh, bw, bh), col)
				y -= bh
			x += r.randf_range(300, 600)
		elif kind == 1:
			# Candelabro con vela.
			c.draw_rect(Rect2(x - 5, base - 380, 10, 380), col)
			c.draw_rect(Rect2(x - 30, base - 390, 60, 10), col)
			c.draw_rect(Rect2(x - 6, base - 420, 12, 30), col.lightened(0.15))
			c.draw_circle(Vector2(x, base - 430), 6, Color(th.glow, 0.45))
			x += r.randf_range(400, 800)
		else:
			# Hojas colgando de un hilo.
			var top := e.position.y + r.randf_range(0, e.size.y * 0.3)
			var hang := r.randf_range(200, 500)
			c.draw_line(Vector2(x, e.position.y), Vector2(x, top + hang), col, 2.0)
			for k in 3:
				c.draw_rect(Rect2(x - 22, top + hang - k * 70, 44, 56), col.lightened(0.04))
			x += r.randf_range(300, 700)


# --- Ríos Asíncronos ----------------------------------------------------------------

func _river_sky(c: CanvasItem, e: Rect2, r: RandomNumberGenerator) -> void:
	var tex := FX.light_texture()
	if th.get("deep", false):
		# Cisterna: bóveda con lucernarios y gotas.
		for i in 5:
			var p := Vector2(e.position.x + e.size.x * (0.1 + i * 0.2), e.position.y + 260)
			c.draw_texture_rect(tex, Rect2(p - Vector2(260, 420), Vector2(520, 1200)), false, Color(0.4, 0.8, 1.6, 0.08))
			c.draw_rect(Rect2(p - Vector2(40, 60), Vector2(80, 30)), Color(0.5, 1.0, 1.8, 0.25))
		for i in 90:
			var sp := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
			c.draw_line(sp, sp + Vector2(0, r.randf_range(8, 22)), Color(0.6, 1.2, 2.0, r.randf_range(0.1, 0.35)), 1.5)
	else:
		# Cielo nublado con claros y lluvia fina.
		for i in 7:
			var p := Vector2(r.randf_range(e.position.x, e.end.x), e.position.y + r.randf_range(100, e.size.y * 0.4))
			var sz := Vector2(r.randf_range(900, 1600), r.randf_range(200, 380))
			c.draw_texture_rect(tex, Rect2(p - sz * 0.5, sz), false, Color(0.6, 0.9, 0.95, 0.07))
		var sun := Vector2(e.position.x + e.size.x * 0.35, e.position.y + e.size.y * 0.28)
		c.draw_texture_rect(tex, Rect2(sun - Vector2(600, 600), Vector2(1200, 1200)), false, Color(0.8, 1.6, 1.6, 0.14))
		for i in 160:
			var sp := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.end.y))
			c.draw_line(sp, sp + Vector2(-4, 18), Color(0.6, 1.0, 1.1, r.randf_range(0.04, 0.12)), 1.0)


func _river_far(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.far
	var base_y := e.position.y + e.size.y * 0.58
	# Acueducto lejano de arcos sobre el horizonte.
	var arch_w := 180.0
	var top := base_y - 260.0
	c.draw_rect(Rect2(e.position.x, top, e.size.x, 50), col)
	var x := e.position.x
	while x < e.end.x:
		c.draw_rect(Rect2(x, top + 50, 36, e.end.y - top), col)
		var pts := PackedVector2Array()
		for k in 13:
			var a := PI + PI * k / 12.0
			pts.append(Vector2(x + 36 + (arch_w - 36) * 0.5 + cos(a) * (arch_w - 36) * 0.5, top + 130 + sin(a) * 80))
		pts.append(Vector2(x + arch_w, top + 50))
		pts.append(Vector2(x + 36, top + 50))
		c.draw_colored_polygon(pts, col)
		x += arch_w
	# Cascadas que caen del canal.
	for i in int(e.size.x / 700.0) + 1:
		var wx := r.randf_range(e.position.x, e.end.x)
		var ww := r.randf_range(26, 60)
		c.draw_rect(Rect2(wx, top + 10, ww, e.end.y - top), Color(0.5, 1.2, 1.3, 0.12))
		c.draw_rect(Rect2(wx + ww * 0.3, top + 10, ww * 0.2, e.end.y - top), Color(0.8, 1.6, 1.7, 0.1))
	# Colinas y delta.
	c.draw_rect(Rect2(e.position.x, base_y, e.size.x, e.end.y - base_y), col.darkened(0.2))
	var hx := e.position.x
	while hx < e.end.x:
		var hw := r.randf_range(300, 700)
		var hh := r.randf_range(60, 160)
		var hp := PackedVector2Array()
		for k in 11:
			var a := PI * k / 10.0
			hp.append(Vector2(hx + hw * k / 10.0, base_y - sin(a) * hh))
		hp.append(Vector2(hx + hw, base_y + 4))
		hp.append(Vector2(hx, base_y + 4))
		c.draw_colored_polygon(hp, col.darkened(0.2))
		hx += hw * 0.8


func _river_mid(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.mid
	var x := e.position.x + r.randf_range(-100, 100)
	while x < e.end.x:
		var wdt := r.randf_range(120, 220)
		var top := e.position.y + r.randf_range(e.size.y * 0.15, e.size.y * 0.45)
		# Pilar de sillares.
		c.draw_rect(Rect2(x, top, wdt, e.end.y - top), col)
		var by := top + 40.0
		while by < e.end.y:
			c.draw_line(Vector2(x, by), Vector2(x + wdt, by), Color(th.rim, 0.06), 2.0)
			by += 46.0
		c.draw_rect(Rect2(x - 16, top - 20, wdt + 32, 24), col)
		# Caño con chorro.
		if r.randf() < 0.5:
			var sy := top + r.randf_range(60, 200)
			c.draw_rect(Rect2(x + wdt, sy, 40, 14), col)
			c.draw_rect(Rect2(x + wdt + 30, sy + 10, 10, e.end.y - sy), Color(th.glow, 0.05))
		x += wdt + r.randf_range(240, 520)
	# Tuberías horizontales entre pilares.
	for i in int(e.size.x / 1100.0) + 1:
		var py := r.randf_range(e.position.y + e.size.y * 0.3, e.end.y - 300)
		c.draw_rect(Rect2(e.position.x + r.randf_range(0, e.size.x * 0.5), py, r.randf_range(600, 1200), 18), Color(col.lightened(0.05), 1.0))


func _river_near(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.near
	var x := e.position.x + r.randf_range(0, 200)
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		var base := e.end.y
		if kind == 0:
			# Juncos.
			for k in r.randi_range(6, 12):
				var bx := x + r.randf_range(-60, 60)
				var hgt := r.randf_range(160, 380)
				c.draw_line(Vector2(bx, base), Vector2(bx + r.randf_range(-30, 30), base - hgt), col, r.randf_range(4, 8))
			x += r.randf_range(300, 600)
		elif kind == 1:
			# Arco roto con musgo colgante.
			var aw := r.randf_range(260, 420)
			var ah := r.randf_range(420, 700)
			c.draw_rect(Rect2(x, base - ah, 60, ah), col)
			c.draw_rect(Rect2(x + aw - 60, base - ah * 0.7, 60, ah * 0.7), col)
			c.draw_rect(Rect2(x, base - ah - 40, aw * 0.7, 50), col)
			for k in 6:
				var mx := x + r.randf_range(0, aw * 0.7)
				c.draw_line(Vector2(mx, base - ah + 10), Vector2(mx, base - ah + r.randf_range(40, 140)), Color(col.lightened(0.1), 0.8), 3.0)
			x += aw + r.randf_range(300, 600)
		else:
			# Farol de muelle.
			c.draw_rect(Rect2(x, base - 320, 14, 320), col)
			c.draw_rect(Rect2(x - 16, base - 350, 46, 34), col)
			c.draw_circle(Vector2(x + 7, base - 333), 10, Color(th.accent, 0.35))
			x += r.randf_range(400, 800)


# --- Cañones Flexibles --------------------------------------------------------------

func _canyon_sky(c: CanvasItem, e: Rect2, r: RandomNumberGenerator) -> void:
	var tex := FX.light_texture()
	if th.get("night", false):
		var moon := Vector2(e.position.x + e.size.x * 0.72, e.position.y + e.size.y * 0.22)
		c.draw_texture_rect(tex, Rect2(moon - Vector2(420, 420), Vector2(840, 840)), false, Color(1.0, 0.8, 0.9, 0.14))
		c.draw_circle(moon, 56, Color(1.6, 1.4, 1.3))
		for i in 140:
			var sp := Vector2(r.randf_range(e.position.x, e.end.x), r.randf_range(e.position.y, e.position.y + e.size.y * 0.5))
			c.draw_circle(sp, r.randf_range(0.8, 2.0), Color(1.3, 1.25, 1.4, r.randf_range(0.2, 0.8)))
	else:
		# Sol bajo del atardecer y bandas de calima.
		var sun := Vector2(e.position.x + e.size.x * 0.62, e.position.y + e.size.y * 0.52)
		c.draw_texture_rect(tex, Rect2(sun - Vector2(700, 700), Vector2(1400, 1400)), false, Color(2.0, 1.0, 0.45, 0.22))
		c.draw_circle(sun, 120, Color(2.4, 1.3, 0.55))
		for i in 6:
			var y := sun.y - 60 + i * 34
			c.draw_rect(Rect2(e.position.x, y, e.size.x, 6), Color(0.45, 0.18, 0.2, 0.25))
	# Rejilla de layout tenue en el cielo.
	var gx := e.position.x
	while gx < e.end.x:
		c.draw_line(Vector2(gx, e.position.y), Vector2(gx, e.end.y), Color(th.accent, 0.025), 2.0)
		gx += 240.0


func _canyon_mesas(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	for layer in 2:
		var col: Color = th.far.lerp(th.sky_bottom, 0.45 - layer * 0.3)
		var base_y := e.position.y + e.size.y * (0.62 + layer * 0.08)
		var x := e.position.x - 100
		while x < e.end.x:
			var wdt := r.randf_range(260, 620)
			var hgt := r.randf_range(160, 420) - layer * 60
			var top := base_y - hgt
			# Meseta con escalones laterales.
			var poly := PackedVector2Array([
				Vector2(x, e.end.y), Vector2(x + 30, top + 60), Vector2(x + 60, top + 40),
				Vector2(x + 80, top), Vector2(x + wdt - 80, top), Vector2(x + wdt - 50, top + 30),
				Vector2(x + wdt - 30, top + 70), Vector2(x + wdt, e.end.y)])
			c.draw_colored_polygon(poly, col)
			# Estratos.
			var sy := top + 26
			while sy < e.end.y:
				c.draw_line(Vector2(x + 50, sy), Vector2(x + wdt - 40, sy + r.randf_range(-4, 4)), Color(col.lightened(0.15), 0.5), 2.0)
				sy += r.randf_range(22, 44)
			x += wdt + r.randf_range(80, 260)
		c.draw_rect(Rect2(e.position.x, base_y, e.size.x, e.end.y - base_y), col)


func _canyon_walls(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.mid
	var x := e.position.x + r.randf_range(-100, 100)
	var pillars := []
	while x < e.end.x:
		var wdt := r.randf_range(160, 320)
		var top := e.position.y + r.randf_range(e.size.y * 0.2, e.size.y * 0.55)
		# Acantilado escalonado (filas flex de roca).
		var steps := r.randi_range(3, 5)
		for k in steps:
			var inset := k * r.randf_range(8, 22)
			var sy := top + (e.end.y - top) * k / steps
			c.draw_rect(Rect2(x - inset, sy, wdt + inset * 2, (e.end.y - top) / steps + 2), col)
			c.draw_line(Vector2(x - inset, sy), Vector2(x + wdt + inset, sy), Color(th.rim, 0.12), 3.0)
		pillars.append(Vector2(x + wdt * 0.5, top))
		x += wdt + r.randf_range(160, 420)
	# Puentes colgantes entre pilares.
	for i in range(0, pillars.size() - 1):
		if r.randf() < 0.6:
			var a: Vector2 = pillars[i] + Vector2(60, 40)
			var b: Vector2 = pillars[i + 1] + Vector2(-60, 40)
			var pts := PackedVector2Array()
			for k in 13:
				var tt := k / 12.0
				pts.append(a.lerp(b, tt) + Vector2(0, sin(tt * PI) * 60.0))
			c.draw_polyline(pts, Color(col.darkened(0.3), 1.0), 3.0, true)
			for k in range(1, 12):
				c.draw_line(pts[k] - Vector2(0, 6), pts[k] + Vector2(0, 8), Color(col.darkened(0.4), 1.0), 5.0)
	# Rieles flex dorados con cajas repartidas (space-between).
	for i in int(e.size.x / 900.0) + 1:
		var ry := r.randf_range(e.position.y + e.size.y * 0.3, e.end.y - 200)
		var rx := r.randf_range(e.position.x, e.end.x - 500)
		var rw := r.randf_range(320, 520)
		# Solo contornos tenues: no deben confundirse con plataformas reales.
		c.draw_line(Vector2(rx, ry), Vector2(rx + rw, ry), Color(col.lightened(0.12), 0.8), 2.0)
		var offs := FlexLayout.justify(rw, [40, 40, 40], "space-between")
		for o in offs:
			c.draw_rect(Rect2(rx + float(o), ry - 26, 40, 22), Color(col.lightened(0.1), 0.7), false, 2.0)


func _canyon_near(c: CanvasItem, e: Rect2, s: int) -> void:
	var r := _rng(s)
	var col: Color = th.near
	var x := e.position.x + r.randf_range(0, 200)
	while x < e.end.x:
		var kind := r.randi_range(0, 2)
		var base := e.end.y
		if kind == 0:
			# Hoodoo: columna de rocas apiladas (flex-direction: column).
			var yy := base
			var stones := r.randi_range(4, 7)
			for k in stones:
				var sw := r.randf_range(70, 130) * (1.0 - k * 0.06)
				var sh := r.randf_range(60, 110)
				c.draw_rect(Rect2(x - sw * 0.5, yy - sh, sw, sh), col)
				c.draw_line(Vector2(x - sw * 0.5, yy - sh), Vector2(x + sw * 0.5, yy - sh), Color(th.rim, 0.08), 2.0)
				yy -= sh
			c.draw_circle(Vector2(x, yy - 20), r.randf_range(40, 70), col)
			x += r.randf_range(380, 700)
		elif kind == 1:
			# Arco de roca.
			var aw := r.randf_range(320, 520)
			var ah := r.randf_range(360, 620)
			var pts := PackedVector2Array()
			for k in 25:
				var a := PI + PI * k / 24.0
				pts.append(Vector2(x + aw * 0.5 + cos(a) * aw * 0.5, base - ah * 0.55 + sin(a) * ah * 0.45))
			var outer := pts.duplicate()
			outer.reverse()
			var shape := PackedVector2Array([Vector2(x - 40, base)])
			shape.append_array(pts)
			shape.append(Vector2(x + aw + 40, base))
			shape.append(Vector2(x + aw + 40, base - ah))
			shape.append(Vector2(x - 40, base - ah))
			c.draw_colored_polygon(PackedVector2Array([Vector2(x - 40, base), Vector2(x + 50, base), Vector2(x + 50, base - ah * 0.6), Vector2(x - 40, base - ah * 0.6)]), col)
			c.draw_colored_polygon(PackedVector2Array([Vector2(x + aw - 50, base), Vector2(x + aw + 40, base), Vector2(x + aw + 40, base - ah * 0.6), Vector2(x + aw - 50, base - ah * 0.6)]), col)
			c.draw_polyline(pts, col, 70.0, true)
			x += aw + r.randf_range(300, 600)
		else:
			# Matorral seco.
			for k in 14:
				var bx := x + r.randf_range(-60, 60)
				c.draw_line(Vector2(bx, base), Vector2(bx + r.randf_range(-30, 30), base - r.randf_range(40, 120)), col, 3.0)
			x += r.randf_range(250, 450)
