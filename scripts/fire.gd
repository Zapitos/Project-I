extends AnimatableBody2D

const SPEED := 400.0
const EXPLOSION = preload("res://prefabricados/explosion.tscn")
@onready var sprite: Sprite2D = $sprite
@onready var fire_collision: CollisionShape2D = $fire_collision
@onready var collision: CollisionShape2D = $collision_detection/collision

var velocity := Vector2.ZERO
var direction


func _process(delta: float) -> void:
	velocity.x = SPEED * direction * delta
	
	move_and_collide(velocity)
	

func set_direction(dir):
	direction = dir
	if direction == 1:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	


func _on_collision_detection_body_entered(_body):
	visible = false
	var explosion_instance = EXPLOSION.instantiate()
	get_parent().add_child(explosion_instance)
	explosion_instance.global_position = global_position
	fire_collision.set_deferred("disabled", true)	
	collision.set_deferred("disabled", true)
	await explosion_instance.animation_finished
	queue_free()
