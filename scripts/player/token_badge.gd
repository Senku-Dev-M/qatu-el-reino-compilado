class_name TokenBadge
extends Node2D
## Distintivo de la habilidad Tokens: muestra el access token vigente, su
## alcance y el tiempo que le queda.

var player: Node
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if player == null or not GameState.has_ability("token"):
		return
	var valid: bool = player.token_ttl > 0.0
	if not valid and not player.has_refresh:
		return
	var font := UITheme.mono_font()
	var gold := Color(2.4, 1.9, 0.8)
	var pos := Vector2(-64, -112)
	if valid:
		var k: float = clampf(player.token_ttl / maxf(player.token_ttl_max(), 0.01), 0.0, 1.0)
		var text := "%s · %ds" % [player.token_scope, ceili(player.token_ttl)]
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		var box := Rect2(pos, Vector2(maxf(ts.x + 20.0, 96.0), 24))
		draw_rect(box, Color(0.05, 0.04, 0.02, 0.8))
		draw_rect(Rect2(box.position, Vector2(box.size.x * k, box.size.y)), Color(gold, 0.22 if k > 0.3 else 0.22 + 0.2 * absf(sin(t * 8.0))))
		draw_rect(box, Color(gold, 0.8), false, 1.5)
		draw_string(font, pos + Vector2(10, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, gold)
	else:
		var text := "sin access token"
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_rect(Rect2(pos, Vector2(ts.x + 20, 24)), Color(0.08, 0.03, 0.03, 0.75))
		draw_rect(Rect2(pos, Vector2(ts.x + 20, 24)), Color(2.4, 0.7, 0.6, 0.7), false, 1.5)
		draw_string(font, pos + Vector2(10, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(2.4, 0.9, 0.8))
	if player.has_refresh:
		draw_circle(pos + Vector2(-10, 12), 6, Color(0.6, 2.2, 2.4, 0.9 if player._refresh_cd <= 0.0 else 0.3))
