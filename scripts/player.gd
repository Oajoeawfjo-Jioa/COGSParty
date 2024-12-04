extends RigidBody2D 
class_name Player

@export var acceleration = 400.0
@export var speed = 800
@export var jump_amount = 1000
@export var color_rect : ColorRect
@export var animated_sprite: AnimatedSprite2D
@export var ground_cast: ShapeCast2D
var device_ID : int = -1

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL
}

var state: State = State.IDLE
var is_on_floor: bool = false


func construct(player_data : MiniGameManager.PlayerData):
	if (player_data.index < len(Input.get_connected_joypads())):
		device_ID = Input.get_connected_joypads()[player_data.index]
	color_rect.modulate = player_data.color


func _process(delta: float) -> void:
	is_on_floor = ground_cast.is_colliding()
	
	if (device_ID < 0):
		return
	
	var direction = Input.get_joy_axis(device_ID, JOY_AXIS_LEFT_X) * acceleration
	
	# Jumping
	if Input.is_joy_button_pressed(device_ID, JOY_BUTTON_LEFT_SHOULDER):
		apply_impulse(Vector2.UP * jump_amount, Vector2.ZERO)
	
	# Horizontal movement
	var curr_speed = abs(linear_velocity.x)
	if (curr_speed <= speed):
		var scaling = (speed - curr_speed) / speed
		apply_impulse(Vector2(direction * scaling, 0), Vector2.ZERO)
