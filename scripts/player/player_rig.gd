class_name PlayerRig
extends Node2D
## Dibujo y animación procedural del Aprendiz: máscara blanca con cuernos
## en forma de < >, capa oscura con franjas tejidas andinas y el Cursor.

var player  # Player
var t := 0.0
var squash := Vector2.ONE
var run_phase := 0.0
var slash_time := 0.0
var slash_dir := Vector2.RIGHT
var slash_style := "corte"
var slash_reach := 1.0
var slash_col := Color(2.5, 2.6, 2.8)
var heal_glow := 0.0
var blink := 0.0
var flash := 0.0
var dissolve := 0.0

const MASK := Color(1.05, 1.05, 1.08)
const EYE := Color(0.01, 0.01, 0.02)
const CLOAK := Color(0.07, 0.075, 0.1)
const CLOAK_EDGE := Color(0.16, 0.17, 0.22)
const WEAVE_A := Color(0.55, 0.2, 0.14)
const WEAVE_B := Color(0.7, 0.5, 0.16)

## Colores y detalle de la vestimenta equipada (content/vestimentas).
var cloak_col := CLOAK
var edge_col := CLOAK_EDGE
var weave_a := WEAVE_A
var weave_b := WEAVE_B
var detail := ""
var sword_col := Color(2.5, 2.6, 2.8)


func _ready() -> void:
	material = FX.flash_material()
	apply_skin(str(GameState.data.get("vestimenta", "base")))
	Events.skin_changed.connect(apply_skin)


static func _col(v: Variant, fallback: Color) -> Color:
	if v is Array and (v as Array).size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return fallback


func apply_skin(id: String) -> void:
	var v := ContentDB.vestimenta(id)
	cloak_col = _col(v.get("capa"), CLOAK)
	edge_col = _col(v.get("borde"), CLOAK_EDGE)
	weave_a = _col(v.get("franja_a"), WEAVE_A)
	weave_b = _col(v.get("franja_b"), WEAVE_B)
	detail = str(v.get("detalle", ""))
	sword_col = _col(v.get("espada"), Color(2.5, 2.6, 2.8))
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	squash = squash.lerp(Vector2.ONE, 1.0 - exp(-12.0 * delta))
	slash_time = maxf(0.0, slash_time - delta)
	flash = maxf(0.0, flash - delta * 5.0)
	var m := material as ShaderMaterial
	m.set_shader_parameter("flash", flash)
	m.set_shader_parameter("dissolve", dissolve)
	if player:
		var speed := absf(player.velocity.x)
		if player.is_on_floor() and speed > 40.0:
			run_phase += delta * speed * 0.028
		else:
			run_phase = lerpf(run_phase, roundf(run_phase / PI) * PI, 1.0 - exp(-10.0 * delta))
		visible = true
		if player.invuln > 0.0 and player.state != player.State.DEAD:
			modulate.a = 0.45 if int(player.invuln * 14.0) % 2 == 0 else 1.0
		else:
			modulate.a = 1.0
	queue_redraw()


func do_squash(v: Vector2) -> void:
	squash = v


func play_slash(dir: Vector2, w := {}) -> void:
	slash_time = 0.16
	slash_dir = dir
	slash_style = str(w.get("estilo", "corte"))
	slash_reach = float(w.get("alcance", 1.0))
	var c: Array = w.get("color", [2.5, 2.6, 2.8])
	slash_col = Color(float(c[0]), float(c[1]), float(c[2]))
	if str(w.get("id", "cursor")) == "cursor":
		slash_col = sword_col  # el Cursor combina con la vestimenta


func _draw() -> void:
	if player == null:
		return
	var facing: float = player.facing
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash.x * facing, squash.y))
	var on_floor: bool = player.is_on_floor()
	var vy: float = player.velocity.y
	var running := on_floor and absf(player.velocity.x) > 40.0
	var bob := sin(run_phase * 2.0) * 3.0 if running else sin(t * 2.4) * 1.2

	# Piernas y botas.
	var leg_a := sin(run_phase) * 9.0 if running else 0.0
	var tuck := 0.0 if on_floor else 6.0
	var pants := cloak_col.darkened(0.45)
	var boots := Color(0.85, 0.88, 0.95) if detail == "anillos" else Color(0.17, 0.12, 0.09)
	for sx: float in [-1.0, 1.0]:
		var foot := Vector2(sx * 7 + leg_a * -sx, -2 - tuck)
		draw_line(Vector2(sx * 7, -18), foot, pants, 7.0, true)
		draw_line(foot + Vector2(0, -6), foot + Vector2(sx * 2.5, 0), boots, 8.0, true)

	# Capa: se inclina según la velocidad.
	var lean := clampf(-player.velocity.x * facing * 0.02, -10.0, 10.0)
	var flutter := sin(t * 9.0) * (3.0 if absf(player.velocity.x) > 40.0 or not on_floor else 1.0)
	var lift := clampf(-vy * 0.012, -10.0, 12.0)
	var top_y := -52.0 + bob
	var cloak := PackedVector2Array([
		Vector2(-14, top_y),
		Vector2(14, top_y),
		Vector2(21 + lean * 0.3, -22 + bob * 0.5),
		Vector2(24 + lean + flutter, -8 - lift),
		Vector2(8, -12 - lift * 0.5),
		Vector2(0 + lean * 0.5, -6 - lift),
		Vector2(-10, -12 - lift * 0.5),
		Vector2(-25 + lean - flutter, -9 - lift),
		Vector2(-21 + lean * 0.3, -22 + bob * 0.5),
	])
	if detail == "chakana":
		# Halo solar detrás del Gran Arquitecto.
		draw_arc(Vector2(0, top_y - 22), 34.0, 0, TAU, 32, Color(1.6, 1.25, 0.45, 0.35 + 0.15 * sin(t * 2.0)), 3.0, true)
	# Capa trasera, más larga y oscura: da el aspecto de poncho sobre capa.
	var back := PackedVector2Array()
	for i in cloak.size():
		var q := cloak[i]
		back.append(q + Vector2(-3.0 - flutter * 0.4, 5.0 if q.y > top_y + 20 else 0.0) if i >= 3 and i <= 7 else q)
	draw_colored_polygon(back, cloak_col.darkened(0.4))
	draw_colored_polygon(cloak, cloak_col)
	# Sombra: la mitad de atrás más oscura.
	draw_colored_polygon(PackedVector2Array([Vector2(0, top_y), cloak[0], cloak[8], cloak[7], cloak[6], cloak[5]]), Color(0, 0, 0, 0.16))
	var band_y := top_y + 16.0
	_draw_cloak_detail(cloak, top_y, band_y)
	# Ribete doble a lo largo del borde inferior.
	var hem := PackedVector2Array([cloak[2], cloak[3], cloak[4], cloak[5], cloak[6], cloak[7], cloak[8]])
	draw_polyline(hem, weave_a, 2.5, true)
	var inner := PackedVector2Array()
	for q in hem:
		inner.append(q + Vector2(-q.x * 0.1, -4.0))
	draw_polyline(inner, Color(weave_b, 0.8), 1.2, true)
	draw_polyline(cloak + PackedVector2Array([cloak[0]]), edge_col, 2.0, true)
	_draw_scarf(top_y, flutter)

	# Cabeza / máscara.
	var head := Vector2(0, top_y - 18 + bob * 0.3)
	# Cuernos < >
	draw_polyline(PackedVector2Array([head + Vector2(-8, -18), head + Vector2(-20, -30), head + Vector2(-10, -42)]), MASK, 5.0, true)
	draw_polyline(PackedVector2Array([head + Vector2(8, -18), head + Vector2(20, -30), head + Vector2(10, -42)]), MASK, 5.0, true)
	var mask_pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var rx := 19.0
		var ry := 20.0 if sin(a) < 0 else 17.0
		mask_pts.append(head + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(mask_pts, MASK)
	# Ojos (parpadeo ocasional).
	_draw_head_detail(head)
	var eye_h := 8.0 if fmod(t, 4.3) > 0.12 else 1.5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash.x * facing, squash.y))
	_ellipse(head + Vector2(-7, 2), 4.2, eye_h, EYE)
	_ellipse(head + Vector2(7, 2), 4.2, eye_h, EYE)

	# Cursor (aguja-puntero) en reposo, a la espalda.
	if slash_time <= 0.0:
		_draw_resting_weapon(Vector2(-12, top_y + 10))

	# Brillo de curación.
	if heal_glow > 0.0:
		draw_circle(Vector2(0, -40), 46.0 * heal_glow, Color(0.8, 2.0, 2.2, 0.12 * heal_glow))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if slash_time > 0.0:
		_draw_slash()


## Bufanda o cuello de la vestimenta, con una punta que ondea.
func _draw_scarf(top_y: float, flutter: float) -> void:
	var scarf := cloak_col.lightened(0.18)
	match detail:
		"rejilla":
			scarf = Color(0.75, 0.38, 0.14)
		"bandolera":
			scarf = Color(0.5, 0.3, 0.14)
		"llave":
			scarf = Color(0.32, 0.16, 0.5)
		"":
			scarf = Color(0.5, 0.2, 0.12)
	var tail := PackedVector2Array([Vector2(-10, top_y + 2), Vector2(-6, top_y + 4), Vector2(-14 - flutter * 0.6, top_y + 20), Vector2(-19 - flutter * 0.6, top_y + 17)])
	draw_colored_polygon(tail, scarf.darkened(0.2))
	var collar := PackedVector2Array([
		Vector2(-16, top_y - 3), Vector2(16, top_y - 3), Vector2(18, top_y + 5),
		Vector2(8, top_y + 9), Vector2(0, top_y + 6), Vector2(-8, top_y + 9), Vector2(-18, top_y + 5),
	])
	draw_colored_polygon(collar, scarf)
	draw_polyline(collar + PackedVector2Array([collar[0]]), Color(weave_a, 0.7), 1.2, true)
	draw_line(Vector2(-14, top_y + 1), Vector2(14, top_y + 1), Color(0, 0, 0, 0.18), 2.0)
	if detail == "llave":
		# Cuello alto con ribete dorado.
		draw_line(Vector2(-16, top_y - 3), Vector2(16, top_y - 3), weave_a, 2.0)


## Motivo de la vestimenta sobre la capa (se dibuja con la orientación del cuerpo).
func _draw_cloak_detail(cloak: PackedVector2Array, top_y: float, band_y: float) -> void:
	var chest := Vector2(2, top_y + 22)
	var hem_y := -14.0
	match detail:
		"":
			# Poncho andino: franjas tejidas y chakanas escalonadas.
			_draw_bands(band_y)
			for i in 3:
				_diamond(Vector2(-10 + i * 10, band_y + 22), 3.5, weave_b)
		"hombrera":
			# Circuitos de endpoints que bajan por la capa.
			for i in 3:
				var x := -10.0 + i * 10.0
				var y0 := band_y - 4.0 + i * 3.0
				var pts := PackedVector2Array([Vector2(x, y0), Vector2(x, y0 + 10), Vector2(x + 4, y0 + 14), Vector2(x + 4, hem_y - 2)])
				draw_polyline(pts, Color(weave_a, 0.8), 1.2)
				draw_circle(Vector2(x, y0), 1.8, weave_a)
			for i in 3:
				draw_line(Vector2(-12, band_y + 8 + i * 4), Vector2(-4 + i * 3, band_y + 8 + i * 4), Color(weave_b, 0.9), 1.5)
			# Hombrera monolítica con remaches.
			var sh := PackedVector2Array([Vector2(-18, top_y - 3), Vector2(-3, top_y - 5), Vector2(-1, top_y + 10), Vector2(-21, top_y + 12)])
			draw_colored_polygon(sh, Color(0.13, 0.11, 0.15))
			draw_polyline(sh + PackedVector2Array([sh[0]]), weave_a, 1.5)
			for q: Vector2 in [Vector2(-15, top_y), Vector2(-6, top_y - 1), Vector2(-17, top_y + 8)]:
				draw_circle(q, 1.4, weave_b.lightened(0.4))
		"anillos":
			# Capas concéntricas de Clean Architecture y franja central blanca.
			draw_line(Vector2(2, band_y - 6), Vector2(2, hem_y), Color(weave_a, 0.5), 3.0)
			draw_arc(chest, 11.0, 0, TAU, 24, weave_a, 1.6, true)
			draw_arc(chest, 7.0, 0, TAU, 20, weave_b, 1.4, true)
			draw_circle(chest, 3.0, weave_b)
			draw_arc(Vector2(-14, band_y + 16), 5.0, PI * 0.5, PI * 1.5, 8, Color(weave_b, 0.6), 1.0)
			draw_arc(Vector2(16, band_y + 16), 5.0, -PI * 0.5, PI * 0.5, 8, Color(weave_b, 0.6), 1.0)
		"hojas":
			# Enredaderas luminosas con hojas.
			for k in 2:
				var sx := -1.0 if k == 0 else 1.0
				var vine := PackedVector2Array()
				for i in 7:
					var y := top_y + 8 + i * 6.0
					vine.append(Vector2(sx * (6 + sin(i * 1.3 + t * 1.5) * 6.0), y))
				draw_polyline(vine, Color(weave_a, 0.85), 1.5, true)
				for i: int in [1, 3, 5]:
					var lp: Vector2 = vine[i]
					draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(sx * 5, -3), lp + Vector2(sx * 3, 2)]), weave_a)
			for i in 4:
				var sp := Vector2(sin(t * 0.8 + i * 1.7) * 14, top_y + 14 + fmod(t * 8 + i * 9, 30))
				draw_circle(sp, 1.1, Color(weave_a, 0.7))
		"rejilla":
			# Cuadrícula dorada de CSS Grid y bandas ajustables.
			_draw_bands(band_y)
			for i in 5:
				var x := -16.0 + i * 8.0
				draw_line(Vector2(x, band_y + 16), Vector2(x + 6, hem_y), Color(weave_a, 0.7), 1.0)
				draw_line(Vector2(x + 8, band_y + 16), Vector2(x + 2, hem_y), Color(weave_a, 0.7), 1.0)
			draw_rect(Rect2(Vector2(-4, band_y + 20), Vector2(8, 6)), Color(weave_a, 0.9), false, 1.2)
		"gemas":
			# Agua que corre: líneas ondulantes y gotas.
			for k in 3:
				var wave := PackedVector2Array()
				for i in 9:
					var x := -16.0 + i * 4.0
					wave.append(Vector2(x, band_y - 2 + k * 9 + sin(x * 0.4 + t * 3.0 + k) * 1.6))
				draw_polyline(wave, Color(weave_a, 0.55 - k * 0.1), 1.2, true)
			for i in 3:
				var dy := fmod(t * 22.0 + i * 11.0, 16.0)
				draw_circle(Vector2(-12 + i * 12, hem_y + dy), 1.3, Color(weave_a, 0.8 * (1.0 - dy / 16.0)))
			var gems: Array[Color] = [Color(1.8, 1.5, 0.3), Color(0.3, 1.8, 0.6), Color(1.9, 0.35, 0.35)]
			for i in 3:
				var gp := Vector2(-8 + i * 8, top_y + 12)
				draw_circle(gp, 4.2, Color(gems[i], 0.25))
				_diamond(gp, 3.0, gems[i])
		"bandolera":
			# Cuero con costuras y bandolera de pergaminos.
			for i in 7:
				var x := -18.0 + i * 6.0
				draw_line(Vector2(x, hem_y - 5), Vector2(x + 3, hem_y - 5), Color(weave_b, 0.7), 1.0)
			draw_line(Vector2(2, band_y), Vector2(2, hem_y - 6), Color(0.2, 0.12, 0.06), 1.0)
			draw_line(Vector2(-15, top_y + 2), Vector2(17, top_y + 34), Color(0.28, 0.16, 0.07), 4.5)
			for i in 3:
				var sp := Vector2(-9 + i * 10, top_y + 8 + i * 10)
				draw_rect(Rect2(sp - Vector2(2.5, 5), Vector2(5, 10)), Color(0.9, 0.82, 0.62))
				draw_line(sp + Vector2(-3, 0), sp + Vector2(3, 0), Color(0.6, 0.2, 0.1), 1.2)
			draw_circle(Vector2(8, band_y + 14), 2.2, weave_b)
		"llave":
			# Ribete dorado grueso, bordados y medalla con cerradura.
			draw_polyline(PackedVector2Array([cloak[2], cloak[3]]), weave_a, 2.0)
			draw_polyline(PackedVector2Array([cloak[8], cloak[7]]), weave_a, 2.0)
			for sx: float in [-1.0, 1.0]:
				draw_arc(Vector2(sx * 11, band_y + 14), 4.0, 0, PI * 1.5, 10, Color(weave_a, 0.7), 1.2)
				draw_arc(Vector2(sx * 13, band_y + 22), 3.0, PI, TAU, 8, Color(weave_a, 0.6), 1.0)
			draw_line(Vector2(-6, top_y + 4), chest, Color(weave_a, 0.8), 1.0)
			draw_line(Vector2(10, top_y + 4), chest, Color(weave_a, 0.8), 1.0)
			draw_circle(chest, 8.0, Color(weave_a, 0.25))
			draw_circle(chest, 6.5, weave_a)
			draw_circle(chest + Vector2(0, -1.5), 1.8, Color(0.1, 0.05, 0.15))
			draw_line(chest + Vector2(0, -1), chest + Vector2(0, 3.5), Color(0.1, 0.05, 0.15), 1.6)
		"timon":
			# Franjas de advertencia en el bajo, botones y timón.
			for i in 8:
				var x := -22.0 + i * 6.0
				var col := weave_a if i % 2 == 0 else Color(0.06, 0.06, 0.06)
				draw_colored_polygon(PackedVector2Array([Vector2(x, hem_y - 7), Vector2(x + 6, hem_y - 7), Vector2(x + 3, hem_y - 1), Vector2(x - 3, hem_y - 1)]), col)
			for i in 3:
				draw_circle(Vector2(-6, band_y + 4 + i * 7), 1.3, Color(0.7, 0.72, 0.75))
			draw_circle(chest, 9.0, Color(0.05, 0.08, 0.12))
			draw_arc(chest, 7.0, 0, TAU, 20, weave_a, 1.8, true)
			for i in 8:
				var a := TAU * i / 8.0 + t * 0.5
				draw_line(chest + Vector2(cos(a), sin(a)) * 2.5, chest + Vector2(cos(a), sin(a)) * 11.0, weave_a, 1.2)
			draw_circle(chest, 2.2, weave_a)
		"lente":
			# Matriz de cobertura y distintivos de prueba superada.
			for gx in 5:
				for gy in 3:
					var cell := Rect2(Vector2(-14 + gx * 6, band_y + 2 + gy * 6), Vector2(4, 4))
					if (gx + gy * 2) % 3 == 0:
						draw_rect(cell, Color(weave_a, 0.8))
					else:
						draw_rect(cell, Color(weave_a, 0.45), false, 0.8)
			for i in 3:
				var cp := Vector2(-10 + i * 9, band_y + 26)
				draw_line(cp + Vector2(-2, 0), cp + Vector2(0, 2), weave_a, 1.4)
				draw_line(cp + Vector2(0, 2), cp + Vector2(3, -2), weave_a, 1.4)
		"chakana":
			# Bordes rojo y oro, chakana y destellos.
			_draw_bands(band_y)
			var g := weave_b
			var cc := chest + Vector2(0, 8)
			draw_circle(cc, 11.0, Color(g, 0.18))
			draw_rect(Rect2(cc - Vector2(3, 9), Vector2(6, 18)), g)
			draw_rect(Rect2(cc - Vector2(9, 3), Vector2(18, 6)), g)
			draw_rect(Rect2(cc - Vector2(6, 6), Vector2(12, 12)), Color(g, 0.7), false, 1.2)
			draw_circle(cc, 1.8, Color(0.1, 0.1, 0.3))
			for i in 3:
				var a := t * 1.2 + TAU * i / 3.0
				var sp := Vector2(cos(a) * 22, top_y + 10 + sin(a) * 10)
				draw_line(sp + Vector2(-2.5, 0), sp + Vector2(2.5, 0), Color(g, 0.9), 1.0)
				draw_line(sp + Vector2(0, -2.5), sp + Vector2(0, 2.5), Color(g, 0.9), 1.0)


func _draw_bands(band_y: float) -> void:
	draw_line(Vector2(-18, band_y), Vector2(18, band_y), weave_a, 4.0)
	var zz := PackedVector2Array()
	for i in 8:
		zz.append(Vector2(-18 + i * 5.2, band_y + 6.0 + (0.0 if i % 2 == 0 else 4.0)))
	draw_polyline(zz, weave_b, 2.0)
	draw_line(Vector2(-20, band_y + 13), Vector2(20, band_y + 13), weave_a, 3.0)


func _diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


## Detalle en la cabeza (hojas en los cuernos, lente del inspector).
func _draw_head_detail(head: Vector2) -> void:
	match detail:
		"hojas":
			var leaf := Color(0.35, 1.5, 0.55)
			for sx: float in [-1.0, 1.0]:
				var base := head + Vector2(sx * 20, -30)
				draw_colored_polygon(PackedVector2Array([base, base + Vector2(sx * 7, -5), base + Vector2(sx * 3, 3)]), leaf)
				draw_colored_polygon(PackedVector2Array([head + Vector2(sx * 12, -40), head + Vector2(sx * 5, -46), head + Vector2(sx * 6, -38)]), leaf)
		"lente":
			draw_arc(head + Vector2(7, 2), 7.5, 0, TAU, 20, Color(0.45, 1.6, 0.7), 1.6, true)
			draw_line(head + Vector2(14, 3), head + Vector2(20, 8), Color(0.45, 1.6, 0.7), 1.2)


func _draw_resting_weapon(c0: Vector2) -> void:
	var style := "corte"
	var col := Color(0.9, 0.95, 1.0)
	if player and player.has_method("weapon"):
		var w: Dictionary = player.weapon()
		style = str(w.get("estilo", "corte"))
		var arr: Array = w.get("color", [2.5, 2.6, 2.8])
		col = Color(minf(float(arr[0]), 1.2), minf(float(arr[1]), 1.2), minf(float(arr[2]), 1.2))
		if str(w.get("id", "cursor")) == "cursor":
			col = Color(minf(sword_col.r, 1.4), minf(sword_col.g, 1.4), minf(sword_col.b, 1.4))
	var shaft := Color(0.45, 0.4, 0.38)
	match style:
		"estocada":
			draw_line(c0 + Vector2(6, -14), c0 + Vector2(-14, 40), shaft, 3.0, true)
			draw_colored_polygon(PackedVector2Array([c0 + Vector2(8, -22), c0 + Vector2(2, -10), c0 + Vector2(11, -12)]), col)
		"pesado", "ancla":
			draw_line(c0, c0 + Vector2(-8, 30), shaft, 4.0, true)
			draw_rect(Rect2(c0 + Vector2(-9, -8), Vector2(18, 12)), col)
		"latigo":
			var pts := PackedVector2Array()
			for i in 6:
				pts.append(c0 + Vector2(-4 - sin(i * 1.2) * 6.0, i * 6.0))
			draw_polyline(pts, col, 2.0, true)
		"doble":
			draw_line(c0, c0 + Vector2(-12, 20), col, 2.5, true)
			draw_line(c0 + Vector2(6, 0), c0 + Vector2(-4, 22), col, 2.5, true)
		"distancia":
			draw_arc(c0 + Vector2(-6, 14), 18.0, -PI * 0.5, PI * 0.5, 10, col, 2.5)
			draw_line(c0 + Vector2(-6, -4), c0 + Vector2(-6, 32), Color(0.8, 0.8, 0.8), 1.0)
		"barrido":
			draw_line(c0 + Vector2(4, -12), c0 + Vector2(-12, 34), shaft, 3.0, true)
			draw_arc(c0 + Vector2(10, -6), 12.0, PI * 0.9, PI * 1.7, 8, col, 3.0)
		_:
			draw_line(c0, c0 + Vector2(-10, 26), col.lerp(Color(0.75, 0.8, 0.85), 0.35), 3.0, true)
			draw_colored_polygon(PackedVector2Array([c0, c0 + Vector2(-6, 9), c0 + Vector2(2, 7)]), col)


func _draw_slash() -> void:
	var k := slash_time / 0.16
	var center := Vector2(0, -42)
	var dir := slash_dir
	if dir.y == 0.0:
		dir = Vector2(player.facing, 0)
	var base_ang := dir.angle()
	var reach := 88.0 * clampf(slash_reach, 0.8, 2.1) if dir.y == 0.0 else 88.0 * clampf(slash_reach, 0.85, 1.35)
	var sweep := 1.9
	var thick := 18.0
	match slash_style:
		"estocada", "latigo", "distancia":
			sweep = 0.35
			thick = 8.0
		"pesado", "ancla":
			sweep = 2.3
			thick = 30.0
		"barrido":
			sweep = 3.6 if slash_dir.y == 0.0 else 2.2
			thick = 22.0
		"doble":
			sweep = 1.4
			thick = 12.0
	if slash_style == "barrido" and slash_dir.y == 0.0:
		# Gira alrededor del cuerpo: golpea delante y detrás.
		base_ang = -PI * 0.5
	var arc_pts := PackedVector2Array()
	var inner := PackedVector2Array()
	var start := base_ang - sweep * 0.5
	for i in 13:
		var a := start + sweep * i / 12.0
		var fade := sin(PI * i / 12.0)
		arc_pts.append(center + Vector2(cos(a), sin(a)) * (reach + thick * fade))
		inner.append(center + Vector2(cos(a), sin(a)) * (reach - (thick + 4.0) * fade))
	inner.reverse()
	var poly := arc_pts + inner
	var col := slash_col
	draw_colored_polygon(poly, Color(col, 0.7 * k))
	draw_polyline(arc_pts, Color(col.lerp(Color(3, 3, 3), 0.3), k), 3.0, true)
	var nd := dir.normalized()
	if slash_style in ["estocada", "latigo"]:
		draw_line(center, center + nd * (reach + 20.0), Color(col, 0.9 * k), 4.0 if slash_style == "estocada" else 2.0, true)
	if slash_style == "doble":
		var off := nd.orthogonal() * 16.0
		var arc2 := PackedVector2Array()
		for p in arc_pts:
			arc2.append(p + off)
		draw_polyline(arc2, Color(col, 0.8 * k), 3.0, true)
	# Punta del arma.
	var tip := center + nd * (reach + 26.0)
	var side := nd.orthogonal() * (14.0 if slash_style in ["pesado", "ancla"] else 9.0)
	draw_colored_polygon(PackedVector2Array([tip, tip - nd * 22.0 + side, tip - nd * 22.0 - side]), Color(col.lerp(Color(3, 3, 3), 0.2), k))


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
