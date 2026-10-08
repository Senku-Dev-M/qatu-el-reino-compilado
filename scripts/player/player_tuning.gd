class_name PlayerTuning
extends Resource
## Valores de "game feel" del Aprendiz. Unidades: píxeles y segundos.

@export var run_speed := 500.0
@export var ground_accel := 9000.0
@export var ground_decel := 11000.0
@export var air_accel := 6500.0
@export var jump_velocity := -1120.0
@export var gravity := 3300.0
@export var fall_gravity_mult := 1.55
@export var max_fall := 1350.0
@export var jump_cut := 0.42
@export var coyote_time := 0.10
@export var jump_buffer := 0.12

@export var attack_cooldown := 0.34
@export var attack_active := 0.11
@export var attack_recoil := 260.0
@export var pogo_velocity := -1500.0
@export var energy_per_hit := 0.11

@export var hurt_knockback := Vector2(460, -520)
@export var hurt_time := 0.22
@export var invuln_time := 1.0

@export var heal_time := 0.9

@export var grapple_range := 400.0
@export var grapple_speed := 1650.0
@export var grapple_exit_speed := 780.0
@export var grapple_max_time := 0.55
