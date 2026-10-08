class_name Regresion
extends BossBase
## Jefe del Laboratorio de Pruebas: La Regresión Crítica.
## Lo que ya se arregló vuelve a fallar: una sombra repite tu recorrido con
## retraso, los bugs cerrados regresan como bumeranes y el suelo muta en
## puntos al azar. Fase 2: escudo que se rompe aplicando los controles OWASP
## correctos. Fase 3: regresión total (sombra + mutaciones).

const MAX_HP := 32
const PHASE2_HP := 20
const PHASE3_HP := 9


func _configure() -> void:
	boss_kind = "regresion"
	max_hp = MAX_HP
	phase2_hp = PHASE2_HP
	phase3_hp = PHASE3_HP
	quiz = OwaspQuiz.new()
	tint = Color(2.5, 0.45, 0.85)
	hurt_size = Vector2(130, 130)
	hurt_offset = Vector2.ZERO


func attacks(p: int) -> Array:
	match p:
		1:
			return ["repeticion", "bugs_reabiertos", "mutacion"]
		2:
			return ["bugs_reabiertos", "mutacion"]
	return ["repeticion", "bugs_reabiertos", "mutacion", "regresion_total"]

func _atk_repeticion() -> void:
	pattern_replay("v1.0", 4.5)


func _atk_bugs_reabiertos() -> void:
	pattern_boomerangs(5 if phase >= 2 else 3, "#bug")


func _atk_mutacion() -> void:
	pattern_floor_blasts(2, 4 if phase >= 2 else 3, "mut")


func _atk_regresion_total() -> void:
	pattern_replay("v1.0", 3.5)
	after(0.5, func() -> void:
		BossAttacks.blast(get_parent(), Vector2(player_pos().x, floor_y - 40), 85.0, 0.9, tint, "mut"))

func _draw_boss() -> void:
	var shake := Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)) * tremble
	var c := shake
	
	var col_neon := Color(2.4, 0.4, 0.8) if phase == 1 else (Color(2.6, 1.4, 0.2) if phase == 2 else Color(2.8, 0.2, 0.2))
	
	# Cristal poliedro de fallo / bug
	var pts := PackedVector2Array()
	for i in 6:
		var a := t * 1.5 + TAU * i / 6.0
		var r := 58.0 + sin(t * 8.0 + i) * 8.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.06, 0.04, 0.08, 0.95))
	draw_polyline(pts, col_neon, 3.5, true)
	
	# Ojo de auditoría SAST central
	draw_circle(c, 20.0, Color(col_neon, 0.25))
	draw_circle(c, 10.0, col_neon)
	draw_circle(c, 4.0, Color(0.02, 0.02, 0.04))
	
	# Etiquetas de vulnerabilidades OWASP orbitantes
	var owasp_labels := ["SQLi", "XSS", "Auth", "SSRF"]
	var font := UITheme.mono_font()
	for i in owasp_labels.size():
		var oa := -t * 1.8 + TAU * i / 4.0
		var opos := c + Vector2(cos(oa) * 98.0, sin(oa) * 54.0)
		draw_circle(opos, 15.0, Color(0.08, 0.04, 0.06, 0.9))
		draw_arc(opos, 15.0, 0, TAU, 16, col_neon, 2.0)
		draw_string(font, opos + Vector2(-12, 5), owasp_labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, col_neon)
