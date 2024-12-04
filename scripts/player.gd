extends RigidBody2D 
class_name Player


signal damaged
signal death


@export var move_acceleration = 100.0
# friction when the player is controllign themselves
@export var control_friction = 50.0
# min and max knockback_amount
@export var knockback_amount = Vector2(200, 600)
@export var knockback_friction = Vector2(3, 1)
# min and max stun
@export var stun_duration = Vector2(0.5, 2)
@export var attack_cooldown = 1.0
@export var dash_cooldown = 2.0
@export var speed = 200.0
@export var jump_amount = 400.0
@export var dash_amount = 300.0
@export var deadzone = 0.25
@export var max_jumps: int = 3
@export var animated_sprite: AnimatedSprite2D
@export var ground_cast: ShapeCast2D
@export var hp_ring: Sprite2D
@export var smoke_particles: GPUParticles2D
@export var visuals_container: Node2D
@export var flippable_container: Node2D
@export var attack_area: Area2D
@export var jump_fx: FX
@export var death_fx: FX
@export var hit_fx: FX
@export var bounce_fx: FX
@export var attack_fx: FX
@export var dash_fx: FX

var jumps_left: int = 3
var health: float
var max_health: float = 10
var friction: float
var device_ID : int = -1
var body_state: BodyState

enum BodyState {
	CONTROL, # Can move, will overwrite velocity to ensure snapping movement
	CONTROL_PHYSICS, # Can move, but won't overwrite x velocity
	PHYSICS # Cannot move, entire body is moved using physics
}

var player_data: MiniGameManager.PlayerData

var is_on_floor: bool = false
var is_controlling: bool = false
var is_running: bool = false
var is_attacking: bool = false
var is_dashing: bool = false
var is_bouncing: bool = false

var prev_move_direction: Vector2 = Vector2.ONE

var _prev_on_floor: bool = false
var _can_attack = true
var _can_dash = true
var _stun_timer: float = 0.0
var _is_dash_pressed: bool = false
var _is_jump_pressed: bool = false
var _is_attack_pressed: bool = false
# Multiplier used to amplify knockback and other negative effects when low on health
# 0 -> Max health
# 1 -> No health
var _invert_health_mult: float :
	get():
		return 1.0 - health / max_health
var _hp_ring_mat: ShaderMaterial


func construct(player_data: MiniGameManager.PlayerData):
	health = max_health
	Input.joy_connection_changed.connect(_on_joy_connection_changed.unbind(2))
	hp_ring.modulate = player_data.color
	hp_ring.material = hp_ring.material.duplicate()
	death_fx.modulate = player_data.color
	attack_fx.modulate = player_data.color
	dash_fx.modulate = player_data.color
	_hp_ring_mat = hp_ring.material as ShaderMaterial
	_hp_ring_mat.set_shader_parameter("fill_amount", health / max_health)
	ground_cast.add_exception(self)
	friction = control_friction
	self.player_data = player_data
	_on_joy_connection_changed()
	visuals_container.scale = Vector2.ZERO
	body_entered.connect(_on_body_entered)
	physics_material_override = physics_material_override.duplicate()
	
	var spawn_tween = create_tween() \
		.set_trans(Tween.TRANS_SPRING) \
		.set_ease(Tween.EASE_OUT) \
		.tween_property(visuals_container, "scale", Vector2.ONE, 0.5)


func _on_body_entered(body: Node):
	if body is PhysicsBody2D:
		# Play bounce fx whenever we collide with something from the ground layer
		# .- Default
		# 000 -> Player
		#  '- Ground
		if body_state == BodyState.PHYSICS and body.collision_layer | (1 << 1):
			bounce_fx.play()


func _on_joy_connection_changed():
	if (player_data.index < len(Input.get_connected_joypads())):
		device_ID = Input.get_connected_joypads()[player_data.index]


func _process(delta: float) -> void:
	if is_controlling and Input.is_action_just_pressed("ui_accept"):
		damage(Vector2(1, -1))
	if _stun_timer > 0:
		_stun_timer -= delta
		if _stun_timer <= 0:
			_stun_timer = 0
			physics_material_override.bounce = 0
			body_state = BodyState.CONTROL
			friction = control_friction
			is_bouncing = false
	smoke_particles.emitting = is_bouncing or is_dashing
	smoke_particles.amount_ratio = linear_velocity.length() / 1200.0


func _physics_process(delta: float) -> void:
	is_on_floor = ground_cast.is_colliding()
	is_controlling = (body_state == BodyState.CONTROL_PHYSICS or body_state == BodyState.CONTROL) and device_ID >= 0
	
	# Horizontal movement
	var direction = Vector2.ZERO
	if is_controlling:
		direction = Vector2(Input.get_joy_axis(device_ID, JOY_AXIS_LEFT_X), Input.get_joy_axis(device_ID, JOY_AXIS_LEFT_Y))
	var curr_speed = abs(linear_velocity.x)
	if abs(direction.length()) > deadzone:
		# Only allow velocity reseting if we are in full control of player
		if body_state == BodyState.CONTROL and sign(prev_move_direction.x) != sign(direction.x):
			linear_velocity.x = 0
		prev_move_direction = direction
		is_running = true
		if curr_speed <= speed:
			var scaling = (speed - curr_speed) / speed
			apply_impulse(Vector2(direction.x * move_acceleration * scaling, 0))
	else:
		is_running = false
		# Apply air resistance/friction to slow player down
		if curr_speed > 0:
			apply_force(Vector2(-1 * linear_velocity.x * friction, 0))
	
	# Jumping
	if _prev_on_floor != is_on_floor:
		_prev_on_floor = is_on_floor
		if is_on_floor:
			jumps_left = max_jumps
	if is_controlling and Input.is_joy_button_pressed(device_ID, JOY_BUTTON_LEFT_SHOULDER):
		if not _is_jump_pressed:
			_is_jump_pressed = true
			jump()
	else:
		_is_jump_pressed = false
	
	# Attack
	if is_controlling and Input.is_joy_button_pressed(device_ID, JOY_BUTTON_RIGHT_SHOULDER):
		if not _is_attack_pressed:
			_is_attack_pressed = true
			attack()
	else:
		_is_attack_pressed = false
	
	# Dash
	if is_controlling and Input.is_joy_button_pressed(device_ID, JOY_BUTTON_A):
		if not _is_dash_pressed:
			_is_dash_pressed = true
			dash()
	else:
		_is_dash_pressed = false
	
	# Update visuals
	var anim = "idle"
	if is_running and is_on_floor:
		anim = "run"
	elif not is_on_floor:
		anim = "fall"
	if is_attacking:
		anim = "attack"

	flippable_container.scale.x = -1 if prev_move_direction.x < 0 else 1
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)


# Damaging is like smash, where it knocks the player back and temporarily stuns the player (no control)
func damage(direction: Vector2):
	health -= 1
	_hp_ring_mat.set_shader_parameter("fill_amount", health / max_health)
	linear_velocity = Vector2.ZERO
	apply_impulse(direction.normalized() * lerp(knockback_amount.x, knockback_amount.y, _invert_health_mult))
	_stun_timer = lerp(stun_duration.x, stun_duration.y, _invert_health_mult)
	friction = lerp(knockback_friction.x, knockback_friction.y, _invert_health_mult)
	physics_material_override.bounce = 0.9
	is_bouncing = true
	hit_fx.play()
	body_state = BodyState.PHYSICS


# Only kill player when they are out of bounds
func kill():
	# Rotate death fx to aim towards center of screen
	var dir = Vector2.ZERO - global_position;
	death_fx.rotate(atan2(dir.y, dir.x))
	death_fx.play()
	death.emit()
	queue_free()


func jump():
	if jumps_left <= 0:
		return
	jumps_left -= 1
	jump_fx.play()
	linear_velocity.y = 0
	apply_impulse(Vector2.UP * jump_amount)


func dash():
	if not _can_dash:
		return
	_can_dash = false
	is_dashing = true
	dash_fx.rotation = prev_move_direction.angle()
	dash_fx.play()
	if is_controlling:
		linear_velocity = Vector2.ZERO
	apply_impulse(prev_move_direction * dash_amount)
	await get_tree().create_timer(0.5).timeout
	is_dashing = false
	await get_tree().create_timer(dash_cooldown - 0.5).timeout
	_can_dash = true


func attack():
	if not _can_attack:
		return
	attack_fx.play()
	_can_attack = false
	is_attacking = true
	var attacked_players = {}
	var time = 0
	while time < 0.25:
		for body in attack_area.get_overlapping_bodies():
			if body != self and not body in attacked_players and body is Player:
				var direction = (body.global_position - global_position).normalized().rotated(deg_to_rad(randf_range(-20, 20)))
				body.damage(direction)
				attacked_players[body] = true
		await get_tree().process_frame
		time += get_process_delta_time()
	await get_tree().create_timer(0.25).timeout
	is_attacking = false
	await get_tree().create_timer(attack_cooldown - 0.5).timeout
	_can_attack = true
