extends RigidBody2D 

#start using script as a class wtfff??
class_name Player

@export var acceleration = 400.0
@export var speed = 800
@export var color_rect : ColorRect
var device_ID : int = -1
var screen_size = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	print(screen_size)
	position.x = 0
	position.y = 0
	
	

func construct(player_data : MiniGameManager.PlayerData):
	if (player_data.index < len(Input.get_connected_joypads())):
		device_ID = Input.get_connected_joypads()[player_data.index]
	color_rect.modulate = player_data.color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (device_ID < 0):
		return
	var direction = Input.get_joy_axis(device_ID, JOY_AXIS_LEFT_X) * acceleration
	
	if (linear_velocity.length() <= speed):
		apply_impulse(Vector2(direction,0), Vector2.ZERO)
	
	
	
