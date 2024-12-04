@tool
extends Area2D
class_name Hill


signal player_owner_changed(new_owner: MiniGameManager.PlayerData)


@export var radius: float
# Time it takes to capture the hill
@export var capture_duration: float = 5
# How much is captured by the current player
@export_range(0, 1.0) var capture_amount: float = 0
@export var sprite: Sprite2D
@export var neutral_color: Color = Color.WHITE
@export var contested_label: Label

# Player that currently owns the hill
var player_owner: MiniGameManager.PlayerData = null :
	get:
		return player_owner
	set(v):
		var old = player_owner
		player_owner = v
		if old != v:
			player_owner_changed.emit(player_owner)
# [player_index: int] = MiniGameManager.PlayerData
var players_inside: Dictionary
# Is another player capturing
var is_hostile_capturing: bool :
	get:
		return player_capturer != null and (player_owner == null or player_capturer != player_owner)
# Is the owner defending the hill
var is_owner_defending: bool :
	get:
		return player_owner != null and player_capturer == player_owner
# Are multiple players in the hill at the same time?
var is_contested: bool :
	get:
		return len(players_inside) > 1
# Player that's currently trying to capture the hill, could be the owner
var player_capturer: MiniGameManager.PlayerData :
	get:
		# If there's only one player inside the hill,
		# and the player isn't the owner,
		# then the one player inside the hill is capturing the hill.
		if len(players_inside) == 1:
			var capturer = players_inside[players_inside.keys()[0]]
			return capturer
		return null

var _capture_timer: float = 0
var _circle_shape: CircleShape2D
var _sprite_mat: ShaderMaterial :
	get:
		return sprite.material as ShaderMaterial


func _ready() -> void:
	var collision_shape = null
	for child in get_children():
		if child is CollisionShape2D:
			collision_shape = child
	if collision_shape == null:
		return
	_circle_shape = collision_shape.shape as CircleShape2D
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.material = sprite.material.duplicate()
	_update_visuals()


func _on_body_entered(body: Node2D):
	if body is Player:
		if not body.player_data.index in players_inside:
			players_inside[body.player_data.index] = body.player_data


func _on_body_exited(body: Node2D):
	if body is Player:
		if body.player_data.index in players_inside:
			players_inside.erase(body.player_data.index)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_visuals()
		return
	
	if is_hostile_capturing:
		if player_owner != null:
			# Remove existing player's capture
			capture_amount -= delta / capture_duration
			if capture_amount <= 0:
				capture_amount = 0
				player_owner = null
		else:
			# Capture neutral hill
			capture_amount += delta / capture_duration
			if capture_amount >= 1:
				capture_amount = 1
				player_owner = player_capturer
	if is_owner_defending:
		# Repair capture amount if the owner is defending
		capture_amount += delta / capture_duration
		if capture_amount >= 1:
			capture_amount = 1
	
	_update_visuals()


func _update_visuals():
	_circle_shape.radius = radius
	_sprite_mat.set_shader_parameter("radius", radius)
	var hill_color = neutral_color
	if player_owner:
		hill_color = player_owner.color
	contested_label.visible = is_contested
	sprite.modulate = hill_color
	_sprite_mat.set_shader_parameter("capture_amount", capture_amount)
