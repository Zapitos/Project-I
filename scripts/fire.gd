extends AnimatableBody2D

const SPEED := 100.0
const EXPLOSION = preload("res://prefabricados/explosion.tscn")
@onready var sprite: Sprite2D = $sprite


var velocity := Vector2.ZERO
var direction

func _ready() -> void:
	set_direction(1)


func _process(delta: float) -> void:
	velocity.x = SPEED * direction * delta
	
	move_and_collide(velocity)
	

func set_direction(dir):
	direction = dir
	if direction == 1:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	


func _on_collision_detection_body_entered(body: Node2D) -> void:
	visible = false
	var explosion_instance = EXPLOSION.instantiate()
	get_parent().add_child(explosion_instance)
	explosion_instance.global_position = global_position
	await explosion_instance.animation_finished
	queue_free()
