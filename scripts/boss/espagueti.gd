class_name Espagueti
extends BossBase
## Jefe de las Torres de Arquitectura: El Espagueti Arquitectónico.
## Todo depende de todo: lanza anillos de dependencias circulares, latigazos
## de acoplamiento directo hacia el jugador y salta de un sitio a otro sin
## orden (goto). Fase 2: escudo que se rompe asignando cada componente a su
## capa de Clean Architecture. Fase 3: el enredo total (anillos + latigazos).

const MAX_HP := 30
const PHASE2_HP := 19
const PHASE3_HP := 9


func _configure() -> void:
	boss_kind = "espagueti"
	max_hp = MAX_HP
	phase2_hp = PHASE2_HP
	phase3_hp = PHASE3_HP
	quiz = ArchQuiz.new()
	tint = Color(0.3, 2.2, 2.4)
	hurt_size = Vector2(130, 130)
	hurt_offset = Vector2.ZERO


func attacks(p: int) -> Array:
	match p:
		1:
			return ["dependencias_circulares", "latigazo", "goto"]
		2:
			return ["dependencias_circulares", "latigazo"]
	return ["dependencias_circulares", "latigazo", "goto", "enredo"]

func _atk_dependencias_circulares() -> void:
	pattern_rings(3 if phase >= 2 else 2, 10, 230.0, "import", 0.6)


func _atk_latigazo() -> void:
	pattern_whips(3 if phase < 3 else 4, "new Repo()")


func _atk_goto() -> void:
	pattern_teleport("goto")


func _atk_enredo() -> void:
	pattern_whips(2, "new Repo()")
	after(0.4, func() -> void:
		BossAttacks.ring(get_parent(), global_position, 12, 210.0, t, "import", tint))

func _draw_boss() -> void:
	var shake := Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)) * tremble
	var c := shake
	
	var col_neon := Color(0.2, 2.2, 2.5) if phase == 1 else (Color(1.0, 1.4, 2.8) if phase == 2 else Color(2.8, 0.4, 1.6))
	var col_vein := Color(col_neon.r * 0.8, col_neon.g * 0.5, col_neon.b * 1.2)
	
	# Tentáculos de dependencia caótica
	for i in 8:
		var base_a := t * (1.2 if phase < 3 else 2.4) + TAU * i / 8.0
		var pts := PackedVector2Array()
		pts.append(c)
		for seg in 6:
			var sk := (seg + 1) / 6.0
			var wave := sin(t * 6.0 + i * 2.0 + seg * 1.5) * 22.0
			var arm := c + Vector2(cos(base_a), sin(base_a)) * (sk * 105.0) + Vector2(-sin(base_a), cos(base_a)) * wave
			pts.append(arm)
		draw_polyline(pts, Color(col_vein, 0.75), 3.0, true)
		draw_circle(pts[6], 4.5, col_neon)
	
	# Núcleo del monstruo espagueti
	draw_circle(c, 56.0, Color(0.04, 0.05, 0.08, 0.95))
	draw_arc(c, 56.0, 0, TAU, 32, col_neon, 3.5, true)
	draw_circle(c, 38.0, Color(col_neon, 0.15))
	
	# Ojo central de Arquitectura
	var eye_col := Color(col_neon.r * 1.3, col_neon.g * 1.3, col_neon.b * 1.3)
	draw_circle(c, 14.0, eye_col)
	draw_circle(c, 6.0, Color(0.02, 0.02, 0.04))
	
	# Runas de Principios SOLID orbitantes (S, O, L, I, D)
	var solid_tags := ["S", "O", "L", "I", "D"]
	var font := UITheme.mono_font()
	for i in solid_tags.size():
		var sa := -t * 1.8 + TAU * i / 5.0
		var spos := c + Vector2(cos(sa) * 88.0, sin(sa) * 52.0)
		draw_circle(spos, 14.0, Color(0.06, 0.08, 0.12, 0.9))
		draw_arc(spos, 14.0, 0, TAU, 16, col_neon, 2.0)
		draw_string(font, spos + Vector2(-5, 5), solid_tags[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, col_neon)
