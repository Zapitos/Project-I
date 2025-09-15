class_name player extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -250.0
@export var double_jump_velocity : float = -200


@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jumped : bool = false
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false

signal player_has_died()

var knockback_vector := Vector2.ZERO




func _physics_process(delta: float):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		was_in_air = true
	else:
		has_double_jumped = false
		
		#if was_in_air == true:
			#land()
			#
		#was_in_air = false
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# Normal jump from floor
			jump()
		elif not has_double_jumped:
			# Double jump in air
			double_jump()
	
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("left", "right", "up", "down")
	
	if direction.x != 0 && animated_sprite.animation != "jump_end":
		velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	
	
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector
	
	
	move_and_slide()
	update_animation()
	update_facing_direction()
	
func update_animation():
	if not animation_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		else:
			if direction.x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")

func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
		
func jump():
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animation_locked = true
	
func double_jump():
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_double")
	animation_locked = true
	has_double_jumped = true

#func land():
	#animated_sprite.play("jump_end")
	#animation_locked = true

func _on_animated_sprite_2d_animation_finished():
	if(["jump_end", "jump_start", "jump_double"].has(animated_sprite.animation)):
		animation_locked = false
	
var hearts_list : Array[TextureRect]
var health = 5



func follow_camera(camera):
	var camera_path = camera.get_path()
	remote_transform.remote_path = camera_path
	

func _on_hurtbox_body_entered(body: Node2D) -> void:
	
	if $ray_right.is_colliding():
		take_damage(Vector2(-600,-100))
	elif $ray_left.is_colliding():
		take_damage(Vector2(600,-100))
	elif $ray_up.is_colliding():
		take_damage(Vector2(0, -400))
		
		
func take_damage(knockback_force := Vector2.ZERO, duration:= 0.25):
	
	if Globals.player_life > 0:
		Globals.player_life -= 1
	else:
		queue_free()
		emit_signal("player_has_died")

	if knockback_force != Vector2.ZERO:
		knockback_vector = knockback_force 
		
		var knockback_tween := get_tree().create_tween()
		knockback_tween.tween_property(self, "knockback_vector", Vector2.ZERO, duration)
		animated_sprite.modulate = Color(1, 0, 0, 1)
		knockback_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), duration)
