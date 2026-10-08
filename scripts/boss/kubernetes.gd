class_name Kubernetes
extends BossBase
## Jefe del Puerto de Contenedores: Kubernetes, el Gran Timonel.
## Orquesta en lugar de pelear: crea réplicas (Pods zombi), hace un rolling
## update que recorre la arena dejando un hueco libre y gira el timón
## lanzando Pods en todas direcciones. Fase 2: escudo que se rompe con el
## pipeline correcto. Fase 3: autoescalado (lluvia de Pods).

const MAX_HP := 30
const PHASE2_HP := 19
const PHASE3_HP := 9


func _configure() -> void:
	boss_kind = "kubernetes"
	max_hp = MAX_HP
	phase2_hp = PHASE2_HP
	phase3_hp = PHASE3_HP
	quiz = PipelineQuiz.new()
	tint = Color(0.3, 1.8, 2.8)
	hurt_size = Vector2(144, 144)
	hurt_offset = Vector2.ZERO


func attacks(p: int) -> Array:
	match p:
		1:
			return ["replicas", "rolling_update", "timon"]
		2:
			return ["rolling_update", "timon"]
	return ["replicas", "rolling_update", "timon", "autoescalado"]

func _atk_replicas() -> void:
	pattern_minions("pod_zombi", 2, 3)


func _atk_rolling_update() -> void:
	pattern_rolling("v2")


func _atk_timon() -> void:
	pattern_rings(4 if phase >= 2 else 3, 8, 250.0, "pod", 0.45)


func _atk_autoescalado() -> void:
	pattern_rain(12, ["pod", "HPA", "+1"])

func _draw_boss() -> void:
	var shake := Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)) * tremble
	var c := shake
	
	var col_neon := Color(0.2, 1.8, 2.8) if phase == 1 else (Color(0.4, 2.4, 1.8) if phase == 2 else Color(2.8, 1.0, 0.2))
	
	# Timón de 7 radios de Kubernetes
	var rot := t * (1.5 if phase < 3 else 2.8)
	draw_arc(c, 62.0, 0, TAU, 36, col_neon, 3.5, true)
	draw_circle(c, 62.0, Color(0.04, 0.06, 0.1, 0.95))
	for i in 7:
		var a := rot + TAU * i / 7.0
		var r_end := c + Vector2(cos(a), sin(a)) * 82.0
		draw_line(c, r_end, col_neon, 3.0)
		draw_circle(r_end, 7.0, col_neon)
	
	# Turbina central
	draw_circle(c, 26.0, Color(col_neon, 0.2))
	draw_circle(c, 14.0, col_neon)
	
	# Pods de contenedores orbitantes
	var pod_labels := ["app", "db", "cache", "ing"]
	var font := UITheme.mono_font()
	for i in pod_labels.size():
		var pa := -t * 1.6 + TAU * i / 4.0
		var ppos := c + Vector2(cos(pa) * 105.0, sin(pa) * 58.0)
		draw_rect(Rect2(ppos - Vector2(16, 12), Vector2(32, 24)), Color(0.05, 0.08, 0.14, 0.9))
		draw_rect(Rect2(ppos - Vector2(16, 12), Vector2(32, 24)), col_neon, false, 2.0)
		draw_string(font, ppos + Vector2(-12, 5), pod_labels[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, col_neon)
