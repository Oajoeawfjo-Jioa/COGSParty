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
@export var speed = 200.0
@export var jump_amount = 400.0
@export var deadzone = 0.1
@export var animated_sprite: AnimatedSprite2D
@export var ground_cast: ShapeCast2D
@export var hp_ring: Sprite2D
@export var smoke_particles: GPUParticles2D
@export var visuals_container: Node2D
@export var jump_fx: FX
@export var death_fx: FX
@export var hit_fx: FX
@export var bounce_fx: FX

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

var prev_direction: float = 1

var _stun_timer: float = 0.0;
var _is_jump_pressed: bool = false
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
	smoke_particles.modulate = player_data.color
	death_fx.modulate = player_data.color
	_hp_ring_mat = hp_ring.material as ShaderMaterial
	_hp_ring_mat.set_shader_parameter("fill_amount", health / max_health)
	friction = control_friction
	self.player_data = player_data
	_on_joy_connection_changed()
	visuals_container.scale = Vector2.ZERO
	body_entered.connect(_on_body_entered)
	
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
			smoke_particles.emitting = false
	smoke_particles.amount_ratio = linear_velocity.length() / 1200.0


func _physics_process(delta: float) -> void:
	is_on_floor = ground_cast.is_colliding()
	is_controlling = (body_state == BodyState.CONTROL_PHYSICS or body_state == BodyState.CONTROL) and device_ID >= 0
	
	# Horizontal movement
	var direction = 0
	if is_controlling:
		direction = Input.get_joy_axis(device_ID, JOY_AXIS_LEFT_X)
	var curr_speed = abs(linear_velocity.x)
	if abs(direction) > deadzone:
		# Only allow velocity reseting if we are in full control of player
		if body_state == BodyState.CONTROL and sign(prev_direction) != sign(direction):
			linear_velocity.x = 0
		prev_direction = direction
		is_running = true
		if curr_speed <= speed:
			var scaling = (speed - curr_speed) / speed
			apply_impulse(Vector2(direction * move_acceleration * scaling, 0), Vector2.ZERO)
	else:
		is_running = false
		# Apply air resistance/friction to slow player down
		if curr_speed > 0:
			apply_force(Vector2(-1 * linear_velocity.x * friction, 0))
	
	# Jumping
	if is_controlling and Input.is_joy_button_pressed(device_ID, JOY_BUTTON_LEFT_SHOULDER):
		if not _is_jump_pressed:
			_is_jump_pressed = true
			jump()
	else:
		_is_jump_pressed = false
	
	# Update visuals
	var anim = "idle"
	if is_running and is_on_floor:
		anim = "run"
	elif not is_on_floor:
		anim = "fall"

	animated_sprite.flip_h = prev_direction < 0
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
	smoke_particles.emitting = true
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
	jump_fx.play()
	linear_velocity.y = 0
	apply_impulse(Vector2.UP * jump_amount, Vector2.ZERO)
