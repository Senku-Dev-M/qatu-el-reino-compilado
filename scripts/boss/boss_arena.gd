extends Node2D
## Controla una pelea de jefe: cierra compuertas al entrar, instancia al jefe
## (res://scripts/boss/<kind>.gd) y entrega recompensas al vencerlo.
## Definición: {"type": "boss", "kind": ..., "half_w": ..., "nombre": ...,
##              "musica_zona": ..., "final": id de diálogo, "leccion_recompensa": ...}

const TILE := 64

var room: RoomBase
var def: Dictionary
var boss: Node2D
var trigger: Area2D
var fighting := false
var kind := "nodo_huerfano"


func setup(p_room: RoomBase, p_def: Dictionary) -> void:
	room = p_room
	def = p_def
	kind = str(def.get("kind", "nodo_huerfano"))


func flag() -> String:
	return "jefe:" + kind


func on_room_ready(_room: RoomBase) -> void:
	if GameState.get_flag(flag()):
		return
	var half := float(def.get("half_w", 14)) * TILE
	trigger = Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 1 << 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(half * 1.2, TILE * 10)
	cs.shape = shape
	cs.position = Vector2(0, -TILE * 5)
	trigger.add_child(cs)
	add_child(trigger)
	trigger.body_entered.connect(func(b): if b is Player and not fighting: _start.call_deferred())


## Una palanca de la arena reenvía su acción al jefe.
func on_lever() -> void:
	if is_instance_valid(boss) and boss.has_method("on_lever"):
		boss.on_lever()


func _start() -> void:
	fighting = true
	if RoomRouter.world == null:
		return  # sala construida fuera del juego (pruebas)
	for id in ["gate_w", "gate_e"]:
		var g = room.get_entity(id)
		if g:
			g.close()
	AudioManager.play_music("boss")
	var ui: GameUI = RoomRouter.world.ui
	var boss_name := str(def.get("nombre", "El Nodo Huérfano"))
	ui.show_area_title(boss_name, str(def.get("subtitulo", "Jefe")))
	var half := float(def.get("half_w", 14)) * TILE
	boss = load("res://scripts/boss/%s.gd" % kind).new()
	boss.setup_arena(self, global_position.y, global_position.x - half, global_position.x + half)
	room.entity_layer.add_child(boss)
	boss.global_position = global_position + Vector2(0, -900)
	boss.defeated.connect(_on_defeated)
	boss.health_changed.connect(func(k): ui.boss_bar_set(k))
	ui.boss_bar_show(boss_name)
	AudioManager.play_sfx("boss_roar")
	Events.camera_shake.emit(14.0, 1.2)


func _on_defeated() -> void:
	var ui: GameUI = RoomRouter.world.ui
	ui.boss_bar_hide()
	GameState.set_flag(flag())
	GameState.register_kill(kind)
	Events.boss_defeated.emit(kind)
	for id in ["gate_w", "gate_e"]:
		var g = room.get_entity(id)
		if g:
			g.open()
	AudioManager.play_music(room.music())
	BitOrb.spawn_burst(room.entity_layer, global_position + Vector2(0, -300), 200)
	await get_tree().create_timer(2.2).timeout
	GameState.data.masks_max += 1
	GameState.heal(99)
	var e := ContentDB.enemy(kind)
	await ui.show_banner("Recompensa", str(def.get("recompensa", "Máscara del jefe")), "Tu vida máxima aumenta en una máscara.", str(e.get("leccion", "")))
	await ui.intro(ContentDB.dialogo(str(def.get("final", "final"))))
	ui.notify("Zona completada al %d %%" % roundi(GameState.zone_completion(room.zone)))
	for v in GameState.skins_unlocked_by(kind):
		ui.notify("Nueva vestimenta: %s (Pausa > Vestimentas)" % str(v.get("nombre", "")))
	var portal = room.get_entity("portal_regreso")
	if portal and portal.has_method("refresh"):
		portal.refresh()
	RoomRouter.world.autosave()
