extends Node2D
## Tubería decorativa del acueducto: paquetes de petición viajan hacia el
## servidor y vuelven como respuesta.
##
## Definición: {"type": "pipe", "largo": tiles, "alto": tiles sobre la celda,
##              "peticion": "GET /productos", "respuesta": "200 OK"}

const TILE := 64

var def: Dictionary
var length := 12.0
var t := 0.0


func setup(_room: RoomBase, p_def: Dictionary) -> void:
	def = p_def
	length = float(def.get("largo", 12)) * TILE
	position.y -= float(def.get("alto", 5)) * TILE
	position.x -= TILE * 0.5
	z_index = -15


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var stone := Color(0.06, 0.1, 0.12, 0.85)
	var req := str(def.get("peticion", "GET /productos"))
	var res := str(def.get("respuesta", "200 OK"))
	var font := UITheme.mono_font()
	# Dos canales: ida (arriba) y vuelta (abajo).
	for lane in 2:
		var y := lane * 34.0
		draw_rect(Rect2(0, y - 12, length, 24), stone)
		draw_line(Vector2(0, y - 12), Vector2(length, y - 12), Color(0.4, 1.2, 1.3, 0.3), 2.0)
		draw_line(Vector2(0, y + 12), Vector2(length, y + 12), Color(0.4, 1.2, 1.3, 0.15), 2.0)
	# Soportes de acueducto.
	var x := 40.0
	while x < length:
		draw_rect(Rect2(x - 8, 46, 16, 60), Color(stone, 0.6))
		x += 220.0
	# Terminales: navegador (izquierda) y servidor (derecha).
	draw_rect(Rect2(-54, -34, 50, 90), stone)
	draw_string(font, Vector2(-50, -42), "cliente", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 1.5, 1.6, 0.7))
	draw_rect(Rect2(length + 4, -34, 50, 90), stone)
	for k in 3:
		draw_line(Vector2(length + 12, -20 + k * 24), Vector2(length + 46, -20 + k * 24), Color(2.0, 1.5, 0.5, 0.5), 3.0)
	draw_string(font, Vector2(length - 4, -42), "servidor", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.0, 1.5, 0.6, 0.7))
	# Paquetes.
	var period := 4.0
	for i in 2:
		var k := fmod(t / period + i * 0.5, 1.0)
		var px := k * length
		draw_circle(Vector2(px, 0), 16, Color(0.4, 1.6, 2.4, 0.2))
		draw_circle(Vector2(px, 0), 8, Color(0.6, 1.8, 2.6))
		draw_string(font, Vector2(px - 30, -20), req, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 1.8, 2.4, 0.8))
		var bx := length - fmod(t / period + i * 0.5 + 0.25, 1.0) * length
		draw_circle(Vector2(bx, 34), 16, Color(2.4, 1.6, 0.4, 0.2))
		draw_circle(Vector2(bx, 34), 8, Color(2.6, 1.8, 0.6))
		draw_string(font, Vector2(bx - 20, 64), res, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(2.4, 1.7, 0.6, 0.8))
