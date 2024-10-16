extends Node

@export var minigame_manager : MiniGameManager
@export var player_prefab : PackedScene
@export var spawn_points : Node2D
@export var world : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#attach listener to that signal
	minigame_manager.game_started.connect(on_game_started)

func on_game_started(player_data_array : Array):
	print(player_data_array)
	for i in range(len(player_data_array)):
		var player_instance : Player = player_prefab.instantiate()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
