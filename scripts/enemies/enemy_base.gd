class_name EnemyBase
extends CharacterBody2D
## Base de los bugs: vida, golpes, retroceso, destello, muerte y botín.

var enemy_id := ""
var max_hp := 3
var hp := 3
var bits_drop := 4
var contact_damage := 1
var knock_resist := 0.0
var uses_gravity := true
var body_size := Vector2(56, 40)
var facing := 1.0
var dead := false
var t := 0.0

var flash := 0.0
var knock_time := 0.0
var hurtbox: Area2D
var contact: DamageArea
var body_shape: CollisionShape2D
var dissolve := 0.0

const GRAVITY := 2600.0


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 1 << 2
	collision_mask = 1
	material = FX.flash_material()
	t = randf() * 10.0
	_setup()
	hp = max_hp
	body_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = body_size
	body_shape.shape = rs
	body_shape.position = Vector2(0, -body_size.y * 0.5)
	add_child(body_shape)
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 1 << 4
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	var hs := CollisionShape2D.new()
	var hrs := RectangleShape2D.new()
	hrs.size = body_size + Vector2(14, 14)
	hs.shape = hrs
	hs.position = body_shape.position
	hurtbox.add_child(hs)
	add_child(hurtbox)
	contact = DamageArea.new()
	contact.damage = contact_damage
	var crs := RectangleShape2D.new()
	crs.size = body_size * 0.85
	contact.add_shape(crs, body_shape.position)
	add_child(contact)
	_after_setup()


## Para sobrescribir: se llama cuando los nodos base ya existen.
func _after_setup() -> void:
	pass


## Para sobrescribir.
func _setup() -> void:
	pass


func _ai(_delta: float) -> void:
	pass


func _draw_body() -> void:
	pass


func _on_death() -> void:
	pass


func player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func to_player() -> Vector2:
	var p := player()
	if p == null:
		return Vector2(99999, 99999)
	return p.global_position - global_position


func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 6.0)
	(material as ShaderMaterial).set_shader_parameter("flash", flash)
	(material as ShaderMaterial).set_shader_parameter("dissolve", dissolve)
	if dead:
		return
	if knock_time > 0.0:
		knock_time -= delta
		if uses_gravity:
			velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		move_and_slide()
	else:
		_ai(delta)
	queue_redraw()


func apply_gravity(delta: float) -> void:
	if uses_gravity:
		velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)


func take_hit(hit: Dictionary) -> Dictionary:
	if dead:
		return {"solid": false}
	hp -= int(hit.get("damage", 1))
	flash = 1.0
	AudioManager.play_sfx("enemy_hit")
	Events.hitstop.emit(0.035)
	var dir: Vector2 = hit.get("dir", Vector2.ZERO)
	if dir == Vector2.ZERO or dir.y != 0.0:
		dir = Vector2(signf(global_position.x - Vector2(hit.get("position", global_position)).x), 0)
	var k := (1.0 - knock_resist) * float(hit.get("knock", 1.0))
	if GameState.is_charm_equipped("gap"):
		k *= 1.6
	velocity = Vector2(dir.x * 520.0 * k, -180.0 * k if uses_gravity else dir.y * 300.0 * k)
	if hit.get("dir", Vector2.ZERO) == Vector2.UP and not uses_gravity:
		velocity.y = -400.0 * k
	knock_time = 0.14 * k
	FX.burst(get_parent(), global_position + Vector2(0, -body_size.y * 0.5), Color(1.2, 0.3, 1.0), 8, 350.0, 0.35, 0.3)
	if hp <= 0:
		die()
	return {"solid": true, "energy": true, "pogo": true}


func die() -> void:
	if dead:
		return
	dead = true
	contact.set_enabled(false)
	hurtbox.set_deferred("monitorable", false)
	body_shape.set_deferred("disabled", true)
	if enemy_id != "":
		GameState.register_kill(enemy_id)
	AudioManager.play_sfx("enemy_death")
	Events.camera_shake.emit(5.0, 0.2)
	var center := global_position + Vector2(0, -body_size.y * 0.5)
	FX.burst(get_parent(), center, Color(2.2, 0.5, 1.8), 22, 520.0, 0.6, 0.45)
	FX.burst(get_parent(), center, Color(0.05, 0.05, 0.06), 14, 300.0, 0.8, 0.6)
	BitOrb.spawn_burst(get_parent(), center, bits_drop)
	_on_death()
	var tw := create_tween()
	tw.tween_property(self, "dissolve", 1.0, 0.45)
	tw.tween_callback(queue_free)


func is_wall_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(0, -body_size.y * 0.5)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(facing * (body_size.x * 0.5 + 10), 0), 1)
	return not space.intersect_ray(q).is_empty()


func is_edge_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(facing * (body_size.x * 0.5 + 6), -8)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 40), 1)
	return space.intersect_ray(q).is_empty()


func _draw() -> void:
	_draw_body()


func eye(pos: Vector2, r := 4.0, col := Color(2.4, 0.5, 1.8)) -> void:
	draw_circle(pos, r * 2.2, Color(col, 0.15))
	draw_circle(pos, r, col)
