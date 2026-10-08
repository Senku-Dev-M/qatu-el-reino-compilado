extends EnemyBase
## Escalada de Privilegios: empieza como usuario normal y, si no lo derrotas
## a tiempo, se asciende a sí mismo (usuario → vendedor → admin): más rápido,
## más grande y con más daño.

const ROLES := ["usuario", "vendedor", "admin"]
const ASCENSO := 7.0

var nivel := 0
var ascenso := ASCENSO


func _setup() -> void:
	enemy_id = "escalada_privilegios"
	max_hp = 4
	bits_drop = 9
	body_size = Vector2(52, 62)


func _ai(delta: float) -> void:
	apply_gravity(delta)
	ascenso -= delta
	if ascenso <= 0.0 and nivel < ROLES.size() - 1:
		nivel += 1
		ascenso = ASCENSO
		flash = 1.0
		contact.damage = 1 + nivel
		AudioManager.play_sfx("boss_roar", 0.35)
		Events.camera_shake.emit(6.0, 0.3)
		if not GameState.get_flag("tip:escalada"):
			GameState.set_flag("tip:escalada")
			Events.notify.emit("Se ascendió a sí mismo: comprueba los permisos en el servidor")
	if is_on_floor():
		if is_wall_ahead() or is_edge_ahead():
			facing = -facing
		velocity.x = facing * (80.0 + nivel * 70.0)
	move_and_slide()


func _draw_body() -> void:
	var scale_k := 1.0 + nivel * 0.18
	var dark := Color(0.12, 0.1, 0.18)
	var colors: Array[Color] = [Color(1.6, 1.6, 1.8), Color(2.2, 1.6, 0.6), Color(2.6, 0.7, 0.5)]
	var col: Color = colors[nivel]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * scale_k, scale_k))
	draw_rect(Rect2(-22, -58, 44, 58), dark)
	draw_rect(Rect2(-22, -58, 44, 58), Color(col, 0.6), false, 2.0)
	# Galones del rol.
	for i in nivel + 1:
		draw_line(Vector2(-14, -40 + i * 9), Vector2(14, -40 + i * 9), Color(col, 0.9), 3.0)
	if nivel == ROLES.size() - 1:
		# Corona de administrador.
		draw_colored_polygon(PackedVector2Array([Vector2(-16, -60), Vector2(-8, -74), Vector2(0, -62), Vector2(8, -74), Vector2(16, -60)]), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	eye(Vector2(facing * 10 * scale_k, -44 * scale_k), 3.0, col)
	var font := UITheme.mono_font()
	draw_string(font, Vector2(-40, -78 * scale_k), "rol: " + ROLES[nivel], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(col, 0.9))
