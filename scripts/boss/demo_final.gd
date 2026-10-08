class_name DemoFinal
extends BossBase
## Jefe final del Sanctum: La Demo Final.
## La demostración repasa todo el curso: rayos de acoplamiento del backend,
## anillos de dependencias, rolling updates y la sombra de la regresión, más
## su propio ataque: la cuenta atrás de la demo en vivo. Fase 2: escudo que
## se rompe respondiendo una pregunta de cualquier semana.

const MAX_HP := 36
const PHASE2_HP := 24
const PHASE3_HP := 11


func _configure() -> void:
	boss_kind = "demo_final"
	max_hp = MAX_HP
	phase2_hp = PHASE2_HP
	phase3_hp = PHASE3_HP
	quiz = DemoQuiz.new()
	tint = Color(2.6, 2.2, 0.8)
	hurt_size = Vector2(156, 156)
	hurt_offset = Vector2.ZERO


func attacks(p: int) -> Array:
	match p:
		1:
			return ["backend", "arquitectura", "cuenta_atras"]
		2:
			return ["contenedores", "pruebas"]
	return ["backend", "arquitectura", "contenedores", "pruebas", "cuenta_atras"]

func _atk_backend() -> void:
	pattern_beams([34.0, 150.0], "API", 0.9)


func _atk_arquitectura() -> void:
	pattern_rings(2, 10, 240.0, "MVC", 0.6)


func _atk_contenedores() -> void:
	pattern_rolling("deploy")


func _atk_pruebas() -> void:
	pattern_replay("bug", 4.0)


## Cuenta atrás de la demo en vivo: tres marcas grandes que explotan en orden.
func _atk_cuenta_atras() -> void:
	_hover(Vector2(center_x, floor_y - 480))
	var lane := (right_x - left_x) / 3.0
	var order := [0, 1, 2]
	if rng.randf() < 0.5:
		order = [2, 1, 0]
	for i in 3:
		var x := left_x + lane * (float(order[i]) + 0.5)
		BossAttacks.blast(get_parent(), Vector2(x, floor_y - 80), lane * 0.42, 1.0 + 0.8 * i, tint, str(3 - i))
	after(3.4, finish_attack)

func _draw_boss() -> void:
	var shake := Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)) * tremble
	var c := shake
	
	var col_neon := Color(2.6, 2.2, 0.8) if phase == 1 else (Color(1.0, 2.4, 2.8) if phase == 2 else Color(2.8, 0.8, 0.4))
	
	# Gran corona de arquitectura del Capstone
	var pts := PackedVector2Array()
	for i in 8:
		var a := t * 1.6 + TAU * i / 8.0
		var r := 66.0 + sin(t * 7.0 + i) * 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.06, 0.06, 0.1, 0.95))
	draw_polyline(pts, col_neon, 4.0, true)
	
	# Núcleo estelar
	draw_circle(c, 28.0, Color(col_neon, 0.25))
	draw_circle(c, 16.0, col_neon)
	draw_circle(c, 8.0, Color(0.04, 0.04, 0.08))
	
	# Runas integradas orbitantes
	var cap_labels := ["BACKEND", "CLEAN", "DEVOPS", "QA"]
	var font := UITheme.mono_font()
	for i in cap_labels.size():
		var ca := -t * 1.5 + TAU * i / 4.0
		var cpos := c + Vector2(cos(ca) * 115.0, sin(ca) * 62.0)
		draw_rect(Rect2(cpos - Vector2(26, 11), Vector2(52, 22)), Color(0.06, 0.06, 0.1, 0.9))
		draw_rect(Rect2(cpos - Vector2(26, 11), Vector2(52, 22)), col_neon, false, 2.0)
		draw_string(font, cpos + Vector2(-22, 5), cap_labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 9, col_neon)
