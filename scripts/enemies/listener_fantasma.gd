extends EnemyBase
## Espectro que atraviesa paredes y se duplica si no se elimina a tiempo.

const DUPLICATE_EVERY := 6.0
const MAX_COPIES := 4

var dup_timer := DUPLICATE_EVERY
var lineage: Array = []  # compartido entre copias


func _setup() -> void:
	enemy_id = "listener_fantasma"
	max_hp = 2
	bits_drop = 3
	body_size = Vector2(44, 56)
	uses_gravity = false
	collision_mask = 0


func _after_setup() -> void:
	if lineage.is_empty():
		position.y -= 80
	lineage.append(self)


func _ai(delta: float) -> void:
	var tp := to_player() + Vector2(0, -40)
	if tp.length() < 800.0:
		velocity = velocity.lerp(tp.normalized() * 95.0, 0.05)
		dup_timer -= delta
	else:
		velocity = velocity.lerp(Vector2(sin(t) * 30.0, cos(t * 0.7) * 20.0), 0.05)
	facing = signf(tp.x) if absf(tp.x) > 5.0 else facing
	position += velocity * delta + Vector2(0, sin(t * 2.0) * 0.4)
	if dup_timer <= 0.0:
		dup_timer = DUPLICATE_EVERY
		_duplicate()


func _duplicate() -> void:
	var alive := lineage.filter(func(e): return is_instance_valid(e) and not e.dead)
	if alive.size() >= MAX_COPIES:
		return
	var copy: EnemyBase = load("res://scripts/enemies/listener_fantasma.gd").new()
	copy.lineage = lineage
	get_parent().add_child(copy)
	copy.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-60, 20))
	flash = 1.0
	AudioManager.play_sfx("shade", 0.2)
	FX.burst(get_parent(), global_position + Vector2(0, -28), Color(0.8, 1.6, 2.4), 16, 260.0, 0.5, 0.35, Vector2.ZERO)
	if not GameState.get_flag("tip:listener"):
		GameState.set_flag("tip:listener")
		Events.notify.emit("¡Se duplicó! Un listener sin removeEventListener se acumula")


func _draw_body() -> void:
	var c := Vector2(0, -34)
	var col := Color(0.7, 1.3, 2.0, 0.55)
	var pts := PackedVector2Array()
	for i in 16:
		var a := PI + PI * i / 15.0
		pts.append(c + Vector2(cos(a) * 22, sin(a) * 24))
	for i in 7:
		var x := 22 - i * 7.3
		pts.append(c + Vector2(x, 26 + sin(t * 6.0 + i) * 6.0 + (i % 2) * 6.0))
	draw_colored_polygon(pts, col)
	draw_colored_polygon(pts, Color(0.02, 0.04, 0.08, 0.5))
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-20, 6), "()=>", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.2, 2.2, 2.8, 0.9))
	eye(c + Vector2(-8 * facing, -8), 3.0, Color(1.4, 2.4, 2.8))
	eye(c + Vector2(4 * facing, -8), 3.0, Color(1.4, 2.4, 2.8))
