extends CharacterBody2D


const SPEED = 1500.0

var direction := 1

@onready var platform_detector := $platform_detector as RayCast2D
@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D

func _physics_process(delta: float) -> void:
		
	if not platform_detector.is_colliding() or wall_detector.is_colliding():
		direction *= -1
		platform_detector.scale.x *= -1
		wall_detector.scale.x *= -1
	
	if direction == 1:
		texture.flip_h = false
	else:
		texture.flip_h = true
	
	velocity.x = direction * SPEED * delta
	move_and_slide()
