class_name player extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -250.0
@export var double_jump_velocity : float = -200
@export var wall_jump_velocity_y : float = -250.0
@export var wall_jump_push : float = 240.0
@export var wall_slide_max_speed : float = 80.0


@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var remote_transform := $remote as RemoteTransform2D
@onready var ray_left: RayCast2D = $ray_left
@onready var ray_right: RayCast2D = $ray_right

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jumped : bool = false
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var _suppress_horizontal_this_frame: bool = false

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
	var pressing_left := Input.is_action_pressed("left")
	var pressing_right := Input.is_action_pressed("right")
	var touching_left := ray_left.is_colliding()
	var touching_right := ray_right.is_colliding()
	# Fallback: se os raycasts não detectarem, confie no is_on_wall e na direção pressionada
	if is_on_wall() and not is_on_floor():
		if pressing_left and not touching_left:
			touching_left = true
		elif pressing_right and not touching_right:
			touching_right = true
	var on_wall := (touching_left or touching_right) and not is_on_floor()

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# Normal jump from floor
			jump()
		elif on_wall:
			# Wall jump: impulsiona para o lado oposto da parede
			var push_dir := 0
			if touching_left:
				push_dir = 1
			elif touching_right:
				push_dir = -1
			elif direction.x < 0:
				push_dir = 1
			elif direction.x > 0:
				push_dir = -1
			else:
				push_dir = 1 # default para a direita
			wall_jump(push_dir)
			_suppress_horizontal_this_frame = true
		elif not has_double_jumped:
			# Double jump in air
			double_jump()



	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("left", "right", "up", "down")

	if not _suppress_horizontal_this_frame:
		if direction.x != 0 && animated_sprite.animation != "jump_end":
			velocity.x = direction.x * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)


	# Wall slide (limita velocidade de queda quando encostado e segurando direção para a parede)
	if on_wall and direction.x != 0:
		var pressing_towards_left := touching_left and (pressing_left or direction.x < 0)
		var pressing_towards_right := touching_right and (pressing_right or direction.x > 0)
		if (pressing_towards_left or pressing_towards_right) and velocity.y > wall_slide_max_speed:
			velocity.y = wall_slide_max_speed

	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector


	move_and_slide()
	update_animation()
	update_facing_direction()
	_suppress_horizontal_this_frame = false

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

func wall_jump(push_dir: int) -> void:
	# Empurra o jogador para longe da parede e aplica impulso vertical
	velocity.y = wall_jump_velocity_y
	velocity.x = push_dir * wall_jump_push
	animated_sprite.play("jump_start")
	animation_locked = true
	# Após um wall jump, permitimos que o jogador ainda faça um double jump depois
	has_double_jumped = false

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


func _on_hurtbox_body_entered(_body: Node2D) -> void:

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
