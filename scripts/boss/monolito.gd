class_name Monolito
extends BossBase
## Jefe de las Ruinas del Backend: El Monolito Legado.
## Pesado y rígido: todo está acoplado. Tiende rayos de acoplamiento a dos
## alturas, levanta columnas de timeout 504 con un hueco libre y cae con todo
## su peso (despliegue monolítico). Fase 2: escudo que se rompe diseñando
## la petición REST correcta. Fase 3: fallo en cascada (rayos + columnas).

const MAX_HP := 28
const PHASE2_HP := 18
const PHASE3_HP := 8


func _configure() -> void:
	boss_kind = "monolito"
	max_hp = MAX_HP
	phase2_hp = PHASE2_HP
	phase3_hp = PHASE3_HP
	quiz = RestQuiz.new()
	tint = Color(2.4, 1.3, 0.35)
	hurt_size = Vector2(100, 170)
	hurt_offset = Vector2(0, -85)


func attacks(p: int) -> Array:
	match p:
		1:
			return ["acoplamiento", "timeout_504", "despliegue"]
		2:
			return ["acoplamiento", "timeout_504"]
	return ["acoplamiento", "timeout_504", "despliegue", "cascada"]

func _atk_acoplamiento() -> void:
	# Bajo, alto y (en fase 3) bajo otra vez: saltar, quedarse en el suelo, saltar.
	pattern_beams([34.0, 150.0, 34.0] if phase == 3 else [34.0, 150.0], "acoplamiento", 0.95)


func _atk_timeout_504() -> void:
	pattern_pillars(6, "504", 2 if phase >= 2 else 1)


func _atk_despliegue() -> void:
	pattern_slam()


func _atk_cascada() -> void:
	pattern_pillars(5, "503", 1)
	after(0.2, func() -> void:
		BossAttacks.beam(get_parent(), Vector2(left_x - 40, floor_y - 150), Vector2(right_x + 40, floor_y - 150), 44.0, 1.1, 0.35, tint, "cascada"))

func _draw_boss() -> void:
	var shake := Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)) * tremble
	var c := shake + Vector2(0, -85)
	
	var body_col := Color(0.08, 0.06, 0.1)
	var glow_col := Color(2.4, 1.4, 0.3) if phase == 1 else (Color(0.8, 1.8, 2.6) if phase == 2 else Color(2.8, 0.4, 0.2))
	var neon_col := Color(glow_col.r * 1.2, glow_col.g * 1.1, glow_col.b * 1.2)
	
	for i in 4:
		var ox := -36.0 + i * 24.0
		var p_start := c + Vector2(ox, 80)
		var curve := PackedVector2Array()
		for seg in 8:
			var sk := seg / 7.0
			var sway := sin(t * 3.0 + i * 1.2 + sk * 4.0) * 18.0 * sk
			curve.append(p_start + Vector2(sway, sk * 75.0))
		draw_polyline(curve, Color(0.2, 0.22, 0.28), 3.5, true)
		draw_circle(curve[7], 4.0, neon_col)
	
	var rect := Rect2(c.x - 48, c.y - 80, 96, 160)
	draw_rect(rect, body_col)
	draw_rect(rect, neon_col, false, 3.5)
	
	for row in 5:
		var ry := c.y - 65 + row * 28
		draw_line(Vector2(c.x - 40, ry), Vector2(c.x + 40, ry), Color(neon_col, 0.35), 1.5)
		var led_on: bool = int(t * 8.0 + row) % 2 == 0
		var led_col := Color(0.2, 2.4, 0.8) if led_on else Color(2.4, 0.2, 0.2)
		draw_circle(Vector2(c.x + 32, ry), 3.0, led_col)
	
	var methods := ["GET", "POST", "PUT", "DEL"]
	var font := UITheme.mono_font()
	for i in methods.size():
		var ang := t * 1.8 + TAU * i / float(methods.size())
		var mpos := c + Vector2(cos(ang) * 85.0, sin(ang) * 45.0)
		draw_circle(mpos, 16.0, Color(0.05, 0.05, 0.08, 0.85))
		draw_arc(mpos, 16.0, 0, TAU, 16, neon_col, 2.0)
		draw_string(font, mpos + Vector2(-12, 5), methods[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, neon_col)
	
	draw_string(font, Vector2(c.x - 42, c.y - 45), "MONOLITH", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, neon_col)
	draw_string(font, Vector2(c.x - 44, c.y - 20), "LEGACY v1", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(neon_col, 0.75))
	
	var core_rad := 18.0 + sin(t * 6.0) * 3.0
	draw_circle(Vector2(c.x, c.y + 25), core_rad, Color(neon_col, 0.2))
	draw_circle(Vector2(c.x, c.y + 25), 10.0, neon_col)
