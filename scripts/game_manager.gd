extends Node

@export var respawn_delay: float = 1.0
@export var world_bounds_buffer: float = 128
@export var minigame_manager: MiniGameManager
@export var player_prefab: PackedScene
@export var spawn_points: Node2D
@export var world: Node2D
@export var collision_baker: TilemapCollisionBaker
@export var tilemap_layer: TileMapLayer
@export var camera: Camera2D

var player_data_array: Array[MiniGameManager.PlayerData]
# Map [player_index: int] -> Player
var player_inst_map: Dictionary
var world_bounds: Rect2

func _ready() -> void:
	# Attach listener to that signal
	minigame_manager.game_started.connect(on_game_started)
	collision_baker.bake_tilemaplayer(tilemap_layer)
	get_viewport().size_changed.connect(_update_world_bounds)
	_update_world_bounds()


func _update_world_bounds():
	world_bounds = Rect2()
	var screen_to_world_matrix = get_viewport().canvas_transform.affine_inverse()
	world_bounds.position = screen_to_world_matrix * Vector2.ZERO
	world_bounds.end = screen_to_world_matrix * camera.get_viewport_rect().size
	world_bounds = world_bounds.grow(world_bounds_buffer)


func on_game_started(player_data_array : Array[MiniGameManager.PlayerData]):
	self.player_data_array = player_data_array
	for i in range(len(player_data_array)):
		spawn_player(i, false)


func _process(delta: float) -> void:
	for index in player_inst_map:
		var player = player_inst_map[index] as Player
		if not world_bounds.has_point(player.global_position):
			# Player is out of bounds and we must kill
			player.kill()


func spawn_player(index: int, random_spawn: bool = true):
		var player_instance : Player = player_prefab.instantiate()
		world.add_child(player_instance)
		var spawn_index = index
		if random_spawn:
			spawn_index = randi_range(0, spawn_points.get_child_count() - 1)
		player_inst_map[index] = player_instance
		player_instance.position = spawn_points.get_child(spawn_index).position
		player_instance.construct(player_data_array[index])
		player_instance.death.connect(_on_player_death.bind(index))


func _on_player_death(index: int):
	player_inst_map.erase(index)
	# Respawn player after delay
	await get_tree().create_timer(respawn_delay)
	spawn_player(index)
