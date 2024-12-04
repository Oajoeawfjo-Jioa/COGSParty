extends Node2D
class_name FX


@export var duration: float = 1.0
@export var play_on_awake: bool = true
@export var unparent_on_play: bool = true
@export var free_on_finish: bool = true

var is_playing: bool = false
var time: float = 0


func _ready() -> void:
	if play_on_awake:
		play()


func play():
	if unparent_on_play:
		reparent(World.global)
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
		elif child is AudioStreamPlayer:
			child.pitch_scale = randf_range(0.9, 1.1)
			child.play()


func _process(delta: float) -> void:
	if is_playing and time < duration:
		time += delta
		if time >= duration:
			is_playing = false
			if free_on_finish:
				queue_free()
