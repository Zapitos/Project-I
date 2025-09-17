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

@onready var jump_sfx: AudioStreamPlayer = $jump_sfx

var wall_jumps_left : int = 2 # Variável para controlar os pulos na parede

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_double_jumped : bool = false
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var _suppress_horizontal_this_frame: bool = false
var is_facing_right = true

@export var dash_speed: float = 400.0 # Velocidade do dash
@export var run_speed: float = 300.0   # Velocidade da corrida
var is_dashing: bool = false
var is_running: bool = false
@export var run_start_impulse: float = 500.0 # O quão rápido o personagem começa a correr
@export var run_impulse_duration: float = 0.1 # O tempo do impulso inicial em segundos
var is_impulsing: bool = false
var can_dash: bool = true

signal player_has_died()

var knockback_vector := Vector2.ZERO

var collision_shapes: Array[CollisionShape2D]
var current_animation = ""


func _physics_process(delta: float):

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		was_in_air = true
	else:
		has_double_jumped = false
		wall_jumps_left = 2
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
			jump()
			# Reset the wall jump counter on the ground
			wall_jumps_left = 1 # Note: você tinha 1, mudei para 2 para permitir dois pulos de parede
		elif on_wall and wall_jumps_left > 0:
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
				push_dir = 1
			wall_jump(push_dir)
			_suppress_horizontal_this_frame = true
			wall_jumps_left -= 1
		elif not has_double_jumped:
			double_jump()


	var input_x = Input.get_axis("left", "right")

	if Input.is_action_just_pressed("attack"):
		dash()
		# Reset the run impulse if a dash is performed
		is_impulsing = false
		
	# Verifica se o botão de corrida foi pressionado pela primeira vez
	if Input.is_action_just_pressed("run"):
		is_impulsing = true
		# Inicia um timer para o impulso
		await get_tree().create_timer(run_impulse_duration).timeout
		is_impulsing = false
	
	is_running = Input.is_action_pressed("run")

	if not _suppress_horizontal_this_frame:
		if is_dashing:
			velocity.x = move_toward(velocity.x, 0, dash_speed * 1.5)
		elif is_impulsing:
			# Aplica a velocidade de impulso inicial
			velocity.x = input_x * run_start_impulse
		elif is_running:
			velocity.x = input_x * run_speed
		else:
			velocity.x = input_x * speed
		
		if input_x == 0 && !is_dashing && !is_running:
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
			if is_dashing:
				# Use a animação de corrida para o dash
				animated_sprite.play("run")
			elif is_running:
				# Animação de corrida
				animated_sprite.play("run")
			elif Input.get_axis("left", "right") != 0:
				# Animação de corrida para o movimento normal
				animated_sprite.play("run")
			else:
				# Animação de parado
				animated_sprite.play("idle")
	if Input.is_action_just_pressed("attack"):
		attack()

func update_facing_direction():
	var input_x = Input.get_axis("left", "right")
	if input_x > 0:
		animated_sprite.flip_h = false
	elif input_x < 0:
		animated_sprite.flip_h = true

func jump():
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animation_locked = true
	jump_sfx.play()

func double_jump():
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_double")
	animation_locked = true
	has_double_jumped = true
	jump_sfx.play()

func wall_jump(push_dir: int) -> void:
	# Empurra o jogador para longe da parede e aplica impulso vertical
	velocity.y = wall_jump_velocity_y
	velocity.x = push_dir * wall_jump_push
	animated_sprite.play("jump_start")
	animation_locked = true
	# Após um wall jump, permitimos que o jogador ainda faça um double jump depois
	has_double_jumped = false
	jump_sfx.play()

#func land():
	#animated_sprite.play("jump_end")
	#animation_locked = true
	
func dash():
	can_dash = false
	is_dashing = true
	
	# Aplica o impulso de velocidade
	var dash_direction = 1 if is_facing_right else -1
	velocity.x = dash_direction * dash_speed
	
	# Duração do dash
	await get_tree().create_timer(0.2).timeout
	is_dashing = false
	
	# Cooldown para poder usar o dash novamente (ajuste este valor como quiser)
	await get_tree().create_timer(0.5).timeout
	can_dash = true

func _on_animated_sprite_2d_animation_finished():
	if(["jump_end", "jump_start", "jump_double", "attack"].has(animated_sprite.animation)):
		animation_locked = false

var hearts_list : Array[TextureRect]
var health = 5

func attack():
	animated_sprite.play("attack")
	animation_locked = true

func _on_animation_changed():
	current_animation = animated_sprite.animation

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

	if Globals.player_life > 1:
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
