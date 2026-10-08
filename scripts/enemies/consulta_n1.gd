extends EnemyBase
## Consulta N+1: un tomo que, por cada registro, lanza otra consulta. Invoca
## hojas sueltas mientras sigue vivo.

const MAX_PAGES := 3

var spawn_timer := 2.5
var pages: Array = []


func _setup() -> void:
	enemy_id = "consulta_n1"
	max_hp = 4
	bits_drop = 8
	body_size = Vector2(64, 50)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	spawn_timer -= delta
	var tp := to_player()
	pages = pages.filter(func(p): return is_instance_valid(p) and not p.dead)
	if spawn_timer <= 0.0 and tp.length() < 700.0 and pages.size() < MAX_PAGES:
		spawn_timer = 3.5
		var p: EnemyBase = load("res://scripts/enemies/pagina_suelta.gd").new()
		p.position = position + Vector2(0, -70)
		get_parent().add_child(p)
		pages.append(p)
		flash = 0.6
		AudioManager.play_sfx("spit", 0.2)
		if not GameState.get_flag("tip:n1"):
			GameState.set_flag("tip:n1")
			Events.notify.emit("Consulta N+1: cada hoja es otra consulta. Derrota al tomo")
	if is_on_floor():
		if is_wall_ahead() or is_edge_ahead():
			facing = -facing
		velocity.x = facing * 55.0
	move_and_slide()


func _draw_body() -> void:
	var c := Vector2(0, -25)
	var open := 0.2 + 0.15 * sin(t * 4.0)
	var cover := Color(0.35, 0.12, 0.1)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-32, 22), c + Vector2(0, 26), c + Vector2(0, -20), c + Vector2(-34, -22 - open * 20)]), cover)
	draw_colored_polygon(PackedVector2Array([c + Vector2(32, 22), c + Vector2(0, 26), c + Vector2(0, -20), c + Vector2(34, -22 - open * 20)]), cover.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-26, 16), c + Vector2(0, 20), c + Vector2(0, -14), c + Vector2(-28, -16 - open * 16)]), Color(0.9, 0.84, 0.7))
	draw_colored_polygon(PackedVector2Array([c + Vector2(26, 16), c + Vector2(0, 20), c + Vector2(0, -14), c + Vector2(28, -16 - open * 16)]), Color(0.95, 0.9, 0.78))
	eye(c + Vector2(-10, 0), 3.5, Color(2.4, 1.2, 0.4))
	eye(c + Vector2(10, 0), 3.5, Color(2.4, 1.2, 0.4))
	draw_string(UITheme.mono_font(), Vector2(-24, -62), "N+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(2.4, 1.5, 0.6, 0.9))
