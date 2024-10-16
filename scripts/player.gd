extends RigidBody2D 

#start using script as a class wtfff??
class_name Player

@export var speed = 400.0
@export var color_rect : ColorRect
var screen_size = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	print(screen_size)
	position.x = 0
	position.y = 0
	
func construct(player_data : MiniGameManager.PlayerData):
	color_rect.modulate = player_data.color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
			position.x += 1
	if Input.is_action_pressed("move_left"):
			position.x -= 1
		

func _on_body_entered(body: Node2D) -> void:
	pass
