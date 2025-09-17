extends RigidBody2D

const EXPLOSION = preload("res://prefabricados/explosion.tscn")



func _on_body_entered(body: Node) -> void:
	visible = false
	var explosion_instance = EXPLOSION.instantiate()
	get_parent().add_child(explosion_instance)
	explosion_instance.global_position = global_position
	await explosion_instance.animation_finished
	queue_free()
