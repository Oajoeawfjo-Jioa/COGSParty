extends Node2D
class_name World


static var global: World


func _enter_tree() -> void:
	if global:
		queue_free()
		return
	global = self


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if global == self:
			global = null
