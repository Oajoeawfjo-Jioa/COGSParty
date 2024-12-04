extends Node
class_name GameManager


@export var game_duration: float = 120
@export var hill_point_interval: float = 1
@export var respawn_delay: float = 1.0
@export var world_bounds_buffer: float = 128
@export var minigame_manager: MiniGameManager
@export var player_prefab: PackedScene
@export var spawn_points: Node2D
@export var world: Node2D
@export var collision_baker: TilemapCollisionBaker
@export var tilemap_layer: TileMapLayer
@export var camera: Camera2D
@export var player_ui_prefab: PackedScene
@export var player_ui_container: Control
@export var timer_label: Label
@export var hill: Hill


var player_data_array: Array[MiniGameManager.PlayerData]
# Map [player_index: int] -> Player
var player_inst_map: Dictionary
# Map [player_index: int] -> PlayerUI
var player_ui_map: Dictionary
var world_bounds: Rect2
var timer: float = 0
var hill_point_timer: float = 0


func _ready() -> void:
	# Attach listener to that signal
	minigame_manager.game_started.connect(on_game_started)
	collision_baker.bake_tilemaplayer(tilemap_layer)
	get_viewport().size_changed.connect(_update_world_bounds)
	for child in player_ui_container.get_children():
		child.queue_free()
	_update_world_bounds()
	set_process(false)


func _update_world_bounds():
	world_bounds = Rect2()
	var screen_to_world_matrix = get_viewport().canvas_transform.affine_inverse()
	world_bounds.position = screen_to_world_matrix * Vector2.ZERO
	world_bounds.end = screen_to_world_matrix * camera.get_viewport_rect().size
	world_bounds = world_bounds.grow(world_bounds_buffer)


func on_game_started(player_data_array : Array[MiniGameManager.PlayerData]):
	self.player_data_array = player_data_array
	for i in range(len(player_data_array)):
		var player_ui_inst = player_ui_prefab.instantiate() as PlayerUI
		player_ui_container.add_child(player_ui_inst)
		player_ui_inst.construct(player_data_array[i])
		player_ui_map[i] = player_ui_inst
		spawn_player(i, false)
	timer = game_duration
	set_process(true)


func _process(delta: float) -> void:
	# Kill players out of bounds
	for index in player_inst_map:
		var player = player_inst_map[index] as Player
		if not world_bounds.has_point(player.global_position):
			# Player is out of bounds and we must kill
			player.kill()
	
	# Add points every hill_point_interval
	hill_point_timer -= delta
	if hill_point_timer <= 0:
		if hill.player_owner != null:
			var owner_ui = player_ui_map[hill.player_owner.index] as PlayerUI
			owner_ui.add_points(1)
		while hill_point_timer < 0:
			hill_point_timer += hill_point_interval
	
	# Countdown
	timer -= delta
	if timer <= 0:
		timer = 0
		end_game()
	timer_label.text = str(ceil(timer))


func end_game():
	var results = []
	var player_uis = player_ui_map.values()
	const REWARDS = [3, 2, 1]
	# Sort descending order of poitns
	player_uis.sort_custom(func(a, b): return a.score > b.score)
	for i in range(len(player_uis)):
		if i >= len(REWARDS):
			break
		var player_ui = player_uis[i] as PlayerUI
		results.append({
			"player": player_uis[i].player_data.index, 
			"points": REWARDS[i]
		})
	minigame_manager.end_game(results)


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
	await get_tree().create_timer(respawn_delay).timeout
	spawn_player(index)
