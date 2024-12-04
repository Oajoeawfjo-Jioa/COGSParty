extends Node

@export var minigame_manager : MiniGameManager
@export var player_prefab : PackedScene
@export var spawn_points : Node2D
@export var world : Node2D
@export var collision_baker: TilemapCollisionBaker
@export var tilemap_layer: TileMapLayer

func _ready() -> void:
	# Attach listener to that signal
	minigame_manager.game_started.connect(on_game_started)
	collision_baker.bake_tilemaplayer(tilemap_layer)


func on_game_started(player_data_array : Array):
	print(player_data_array)
	for i in range(len(player_data_array)):
		var player_instance : Player = player_prefab.instantiate()
		
		#always do initialization after add child to avoid uninitialiazation porblems
		
		world.add_child(player_instance)
		player_instance.position = spawn_points.get_child(i).position
		player_instance.construct(player_data_array[i])


func _process(delta: float) -> void:
	pass
