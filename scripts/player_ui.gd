extends Control
class_name PlayerUI


@export var score_label: Label

var score: int = 0
var player_data: MiniGameManager.PlayerData


func construct(player_data: MiniGameManager.PlayerData) -> void:
	self.player_data = player_data
	score = 0
	score_label.text = str(score)
	score_label.modulate = player_data.color


func add_points(points: int):
	score += points
	score_label.text = str(score)
	score_label.scale = Vector2.ONE * 1.5
	var tween = create_tween() \
		.set_trans(Tween.TRANS_SPRING) \
		.set_ease(Tween.EASE_OUT) \
		.tween_property(score_label, "scale", Vector2.ONE, 0.25)
