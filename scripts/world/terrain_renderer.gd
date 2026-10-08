class_name TerrainRenderer
extends Node2D
## Dibuja el terreno de una sala a partir de su grilla con bordes
## orgánicos, musgo, raíces colgantes y bulbos luminosos.

const TILE := 64

var rows: PackedStringArray
var w := 0
var h := 0
var th: Dictionary
var seed_value := 0


func setup(p_rows: PackedStringArray, p_theme: Dictionary, p_seed: int) -> void:
	rows = p_rows
	h = rows.size()
	w = rows[0].length() if h > 0 else 0
	th = p_theme
	seed_value = p_seed
	queue_redraw()


func ch(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= w or y >= h:
		return "#"
	return rows[y][x]


func solid(x: int, y: int) -> bool:
	return ch(x, y) == "#"


func _draw() -> void:
	if h == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rock: Color = th.rock
	var deep: Color = th.rock_deep
	# 1. Relleno con sombreado por profundidad.
	for y in h:
		var x := 0
		while x < w:
			if solid(x, y):
				var x0 := x
				while x < w and solid(x, y):
					x += 1
				draw_rect(Rect2(x0 * TILE - 1, y * TILE - 1, (x - x0) * TILE + 2, TILE + 2), rock)
			else:
				x += 1
	for y in h:
		for x in w:
			if solid(x, y) and _depth(x, y) >= 2:
				draw_rect(Rect2(x * TILE - 1, y * TILE - 1, TILE + 2, TILE + 2), deep)
	# Manchas sutiles en el interior.
	for i in int(w * h * 0.04):
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		if solid(x, y) and _depth(x, y) >= 1:
			draw_circle(Vector2(x * TILE + rng.randf() * TILE, y * TILE + rng.randf() * TILE), rng.randf_range(6, 22), Color(th.rim, 0.025))
	# 2. Bordes.
	_draw_top_edges(rng)
	_draw_bottom_edges(rng)
	_draw_side_edges(rng)
	_draw_platforms(rng)
	_draw_spikes(rng)


func _depth(x: int, y: int) -> int:
	for d in range(1, 3):
		for oy in range(-d, d + 1):
			for ox in range(-d, d + 1):
				if not solid(x + ox, y + oy):
					return d - 1
	return 2


func _runs(y: int, pred: Callable) -> Array:
	var out := []
	var x := 0
	while x < w:
		if pred.call(x, y):
			var x0 := x
			while x < w and pred.call(x, y):
				x += 1
			out.append(Vector2i(x0, x))
		else:
			x += 1
	return out


func _draw_top_edges(rng: RandomNumberGenerator) -> void:
	var rim: Color = FX.hdr(th.rim, 1.9)
	var moss: Color = FX.hdr(th.moss, 1.5)
	var glow: Color = th.glow
	for y in h:
		for run: Vector2i in _runs(y, func(x, yy): return solid(x, yy) and not solid(x, yy - 1)):
			var left := run.x * TILE - (6 if not solid(run.x - 1, y) else 0)
			var right := run.y * TILE + (6 if not solid(run.y, y) else 0)
			var top := float(y * TILE)
			var pts := PackedVector2Array()
			var px := float(left)
			while px < right:
				pts.append(Vector2(px, top + rng.randf_range(-7, 2)))
				px += 14.0
			pts.append(Vector2(right, top + rng.randf_range(-5, 2)))
			var poly := pts.duplicate()
			poly.append(Vector2(right, top + 20))
			poly.append(Vector2(left, top + 20))
			draw_colored_polygon(poly, th.rock)
			draw_polyline(pts, Color(rim, 0.9), 3.0, true)
			draw_polyline(_offset(pts, Vector2(0, 5)), Color(rim, 0.18), 5.0, true)
			# Musgo y hierba.
			for i in range(0, pts.size() - 1):
				var a: Vector2 = pts[i]
				for j in rng.randi_range(0, 3):
					var base := a + Vector2(rng.randf_range(0, 14), 1)
					var tip := base + Vector2(rng.randf_range(-6, 6), -rng.randf_range(6, 24))
					draw_line(base, tip, Color(moss, rng.randf_range(0.5, 0.95)), rng.randf_range(1.5, 2.5), true)
				if rng.randf() < 0.035:
					var stem_h := rng.randf_range(12, 30)
					var b := a + Vector2(7, 0)
					draw_line(b, b + Vector2(rng.randf_range(-4, 4), -stem_h), Color(moss, 0.9), 2.0, true)
					draw_circle(b + Vector2(0, -stem_h), rng.randf_range(3, 5), glow)
					draw_circle(b + Vector2(0, -stem_h), 10, Color(glow, 0.08))


func _draw_bottom_edges(rng: RandomNumberGenerator) -> void:
	for y in h:
		for run: Vector2i in _runs(y, func(x, yy): return solid(x, yy) and not solid(x, yy + 1) and yy + 1 < h):
			var left := run.x * TILE
			var right := run.y * TILE
			var bottom := float((y + 1) * TILE)
			var pts := PackedVector2Array()
			var px := float(left)
			while px < right:
				pts.append(Vector2(px, bottom + rng.randf_range(-2, 9)))
				px += 16.0
			pts.append(Vector2(right, bottom))
			var poly := pts.duplicate()
			poly.append(Vector2(right, bottom - 18))
			poly.append(Vector2(left, bottom - 18))
			draw_colored_polygon(poly, th.rock)
			draw_polyline(pts, Color(th.rim, 0.25), 2.0, true)
			# Raíces colgantes.
			for i in pts.size():
				if rng.randf() < 0.28:
					var a: Vector2 = pts[i]
					var length := rng.randf_range(14, 90)
					var sway := rng.randf_range(-14, 14)
					var root := PackedVector2Array([a, a + Vector2(sway * 0.3, length * 0.5), a + Vector2(sway, length)])
					draw_polyline(root, Color(th.rock, 1.0), rng.randf_range(2.0, 4.5), true)
					if rng.randf() < 0.18:
						draw_circle(root[2], 3.0, th.glow)
						draw_circle(root[2], 9.0, Color(th.glow, 0.07))


func _draw_side_edges(rng: RandomNumberGenerator) -> void:
	for x in w:
		var y := 0
		while y < h:
			var left_open := solid(x, y) and not solid(x - 1, y)
			if left_open:
				var y0 := y
				while y < h and solid(x, y) and not solid(x - 1, y):
					y += 1
				_side_strip(rng, float(x * TILE), y0, y, -1)
			else:
				y += 1
		y = 0
		while y < h:
			var right_open := solid(x, y) and not solid(x + 1, y)
			if right_open:
				var y0 := y
				while y < h and solid(x, y) and not solid(x + 1, y):
					y += 1
				_side_strip(rng, float((x + 1) * TILE), y0, y, 1)
			else:
				y += 1


func _side_strip(rng: RandomNumberGenerator, edge_x: float, y0: int, y1: int, dir: int) -> void:
	var pts := PackedVector2Array()
	var py := float(y0 * TILE)
	while py < y1 * TILE:
		pts.append(Vector2(edge_x + dir * rng.randf_range(-2, 7), py))
		py += 16.0
	pts.append(Vector2(edge_x, y1 * TILE))
	var poly := pts.duplicate()
	poly.append(Vector2(edge_x - dir * 18, y1 * TILE))
	poly.append(Vector2(edge_x - dir * 18, y0 * TILE))
	draw_colored_polygon(poly, th.rock)
	draw_polyline(pts, Color(th.rim, 0.3), 2.0, true)


func _draw_platforms(rng: RandomNumberGenerator) -> void:
	for y in h:
		for run: Vector2i in _runs(y, func(x, yy): return ch(x, yy) == "="):
			var left := run.x * TILE - 8.0
			var right := run.y * TILE + 8.0
			var top := y * TILE + 6.0
			var pts := PackedVector2Array()
			var px := left
			while px <= right:
				pts.append(Vector2(px, top + sin(px * 0.02 + y) * 3.0))
				px += 12.0
			draw_polyline(_offset(pts, Vector2(0, 8)), Color(th.rock, 1), 18.0, true)
			draw_polyline(pts, Color(th.rim, 0.85), 3.0, true)
			for p in pts:
				if rng.randf() < 0.25:
					var l := rng.randf_range(10, 40)
					draw_line(p + Vector2(0, 14), p + Vector2(rng.randf_range(-5, 5), 14 + l), Color(th.moss, 0.7), 2.0, true)
					if rng.randf() < 0.2:
						draw_circle(p + Vector2(0, 14 + l), 2.5, th.glow)


func _draw_spikes(rng: RandomNumberGenerator) -> void:
	if th.get("water", false):
		return  # WaterRenderer dibuja agua animada en su lugar.
	var tip := Color(2.4, 0.4, 1.6)
	for y in h:
		for x in w:
			if ch(x, y) != "^":
				continue
			var base_y := float((y + 1) * TILE)
			for i in 4:
				var bx := x * TILE + 6 + i * 15 + rng.randf_range(-3, 3)
				var height := rng.randf_range(30, 50)
				var top := Vector2(bx + rng.randf_range(-4, 4), base_y - height)
				draw_colored_polygon(PackedVector2Array([Vector2(bx - 8, base_y), top, Vector2(bx + 8, base_y)]), th.rock_deep)
				draw_line(top, top + Vector2(0, 10), tip, 2.5, true)
				draw_circle(top, 3.0, tip)


func _offset(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + off)
	return out
