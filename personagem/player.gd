class_name player extends CharacterBody2D

# Indicador visual simples para mostrar o alcance do ataque
class AttackIndicator:
	extends Node2D
	var size: Vector2
	var lifetime: float
	var elapsed: float = 0.0
	var color: Color = Color(1,1,1,0.55)
	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= lifetime:
			queue_free()
		self.queue_redraw()
	func _draw():
		draw_rect(Rect2(-size * 0.5, size), color, false, 2.0)

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

# Cache de ações para evitar chamar strings repetidamente (micro otimiz.)
const ACTION_LEFT := "left"
const ACTION_RIGHT := "right"
const ACTION_JUMP := "jump"
const ACTION_ATTACK := "attack"
const ACTION_RUN := "run"

var wall_jumps_left : int = 2 # Pulos restantes na parede atual
var last_wall_side : int = 0 # 1 = parede à esquerda, -1 = parede à direita, 0 = nenhuma

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

# Substituem timers criados a cada ação (evita alocações e garbage temporário)
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var run_impulse_time_left: float = 0.0

signal player_has_died()

var knockback_vector := Vector2.ZERO
@export var invulnerability_time: float = 0.9 # tempo de i-frame após levar dano
@export var blink_interval: float = 0.12
var invul_time_left: float = 0.0
var blink_time_left: float = 0.0

var collision_shapes: Array[CollisionShape2D]
var current_animation = ""

# ================= COMBATE =================
@export var attack_cooldown: float = 0.45
@export var attack_active_time: float = 0.18
@export var attack_range: float = 60.0 # alcance aumentado
var attack_cooldown_left: float = 0.0
var attack_active_left: float = 0.0
var _attack_hit_enemies := {}

func _ready():
	add_to_group("player")



func _physics_process(delta: float):
	# ====== Timers de ataque ======
	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta
	if attack_active_left > 0.0:
		attack_active_left -= delta
		_process_attack_hits()
	else:
		if attack_active_left < 0.0:
			attack_active_left = 0.0
	# ====== Atualização de timers e estados temporizados ======
	if invul_time_left > 0.0:
		invul_time_left -= delta
		blink_time_left -= delta
		if blink_time_left <= 0.0:
			# alterna visibilidade para efeito de flicker
			animated_sprite.visible = not animated_sprite.visible
			blink_time_left = blink_interval
	else:
		if not animated_sprite.visible:
			animated_sprite.visible = true
	if dash_time_left > 0.0:
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false
	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0.0:
			can_dash = true
	if run_impulse_time_left > 0.0:
		run_impulse_time_left -= delta
		if run_impulse_time_left <= 0.0:
			is_impulsing = false

	# ====== Gravidade ======
	if not is_on_floor():
		velocity.y += gravity * delta
		was_in_air = true
	else:
		has_double_jumped = false
		wall_jumps_left = 2

	# ====== Inputs (cache) ======
	var pressing_left := Input.is_action_pressed(ACTION_LEFT)
	var pressing_right := Input.is_action_pressed(ACTION_RIGHT)
	var just_jump := Input.is_action_just_pressed(ACTION_JUMP)
	var just_attack := Input.is_action_just_pressed(ACTION_ATTACK)
	var just_run := Input.is_action_just_pressed(ACTION_RUN)
	var run_pressed := Input.is_action_pressed(ACTION_RUN)
	var input_x := Input.get_axis(ACTION_LEFT, ACTION_RIGHT)

	# ====== Detecção de parede (reduz lógica redundante) ======
	var touching_left := ray_left.is_colliding()
	var touching_right := ray_right.is_colliding()
	var airborne := not is_on_floor()
	if is_on_wall() and airborne:
		# fallback simples
		if pressing_left:
			touching_left = true
		elif pressing_right:
			touching_right = true
	var on_wall := airborne and (touching_left or touching_right)

	# ====== Saltos ======
	if just_jump:
		if is_on_floor():
			jump()
			wall_jumps_left = 2
			last_wall_side = 0
		elif on_wall:
			# Determina qual lado da parede está tocando agora
			var current_wall_side := 0
			if touching_left:
				current_wall_side = 1
			elif touching_right:
				current_wall_side = -1
			# Se mudou de lado, reseta a quantidade de wall jumps disponíveis para este lado
			if current_wall_side != 0 and current_wall_side != last_wall_side:
				wall_jumps_left = 2
			if wall_jumps_left > 0:
				# Determina direção de empurrão (sempre oposta à parede atual)
				var push_dir := 1
				if current_wall_side == 1: # parede à esquerda -> empurra para direita
					push_dir = 1
				elif current_wall_side == -1: # parede à direita -> empurra para esquerda
					push_dir = -1
				wall_jump(push_dir)
				_suppress_horizontal_this_frame = true
				wall_jumps_left -= 1
				last_wall_side = current_wall_side
		elif not has_double_jumped:
			double_jump()

	# ====== Dash ======
	if just_attack and can_dash:
		dash() # seta flags, não usa mais timers await
		is_impulsing = false

	# ====== Corrida / impulso inicial ======
	if just_run:
		is_impulsing = true
		run_impulse_time_left = run_impulse_duration

	is_running = run_pressed

	# ====== Movimento horizontal ======
	if not _suppress_horizontal_this_frame:
		if is_dashing:
			# desaceleração suave do dash
			velocity.x = move_toward(velocity.x, 0, dash_speed * 1.5 * delta * 10.0)
		elif is_impulsing:
			velocity.x = input_x * run_start_impulse
		elif is_running:
			velocity.x = input_x * run_speed
		else:
			velocity.x = input_x * speed

		if input_x == 0 and not is_dashing and not is_running and not is_impulsing:
			velocity.x = move_toward(velocity.x, 0, speed * delta * 10.0)

	# ====== Wall slide ======
	if on_wall and input_x != 0:
		var pressing_towards_left := touching_left and input_x < 0
		var pressing_towards_right := touching_right and input_x > 0
		if (pressing_towards_left or pressing_towards_right) and velocity.y > wall_slide_max_speed:
			velocity.y = wall_slide_max_speed

	# ====== Knockback ======
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector

	move_and_slide()
	update_animation(input_x)
	update_facing_direction(input_x)
	_suppress_horizontal_this_frame = false

func update_animation(cached_input_x: float):
	# Evita múltiplas chamadas a Input dentro deste método
	if not animation_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		else:
			if is_dashing or is_running or cached_input_x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")
	if Input.is_action_just_pressed(ACTION_ATTACK):
		attack()

func update_facing_direction(input_x: float):
	if input_x > 0:
		animated_sprite.flip_h = false
		is_facing_right = true
	elif input_x < 0:
		animated_sprite.flip_h = true
		is_facing_right = false

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
	var dash_direction = 1 if is_facing_right else -1
	velocity.x = dash_direction * dash_speed
	# Controlado por contadores no _physics_process
	dash_time_left = 0.2
	dash_cooldown_left = 0.5

func _on_animated_sprite_2d_animation_finished():
	if(["jump_end", "jump_start", "jump_double", "attack"].has(animated_sprite.animation)):
		animation_locked = false

var hearts_list : Array[TextureRect]
var health = 5

func attack():
	if attack_cooldown_left > 0.0:
		return
	attack_cooldown_left = attack_cooldown
	attack_active_left = attack_active_time
	_attack_hit_enemies.clear()
	animated_sprite.play("attack")
	animation_locked = true
	# Ajusta flip da sprite para determinar direção
	var dir := 1 if not animated_sprite.flip_h else -1
	# Pré-checa hits no primeiro frame do ataque
	_process_attack_hits(dir)
	_spawn_attack_indicator(dir)

func _process_attack_hits(dir := 1):
	# Cria uma área de ataque simples (retângulo) na frente do player
	var space := get_world_2d().direct_space_state
	var box_from := global_position + Vector2(dir * attack_range * 0.5, 0)
	var rect_size := Vector2(attack_range, 30)
	var aabb := Rect2(box_from - rect_size * 0.5, rect_size)
	var params := PhysicsShapeQueryParameters2D.new()
	params.collision_mask = 0xFFFFFFFF
	# Usamos um shape retangular
	var shape := RectangleShape2D.new()
	shape.size = rect_size
	params.shape = shape
	params.transform = Transform2D(0, aabb.position + aabb.size * 0.5)
	var results := space.intersect_shape(params, 8)
	for r in results:
		var collider: Object = r.get("collider")
		if collider == self:
			continue
		if collider and collider.is_in_group("enemy") and not _attack_hit_enemies.has(collider):
			_attack_hit_enemies[collider] = true
			if collider.has_method("take_damage"):
				collider.take_damage(1, dir)

func _spawn_attack_indicator(dir: int):
	var ind := AttackIndicator.new()
	ind.size = Vector2(attack_range, 34)
	ind.lifetime = attack_active_time
	ind.position = Vector2(dir * attack_range * 0.5, 0)
	add_child(ind)

func _on_animation_changed():
	current_animation = animated_sprite.animation

func follow_camera(camera):
	var camera_path = camera.get_path()
	remote_transform.remote_path = camera_path


func _on_hurtbox_body_entered(_body: Node2D) -> void:
	if invul_time_left > 0.0:
		return
	if $ray_right.is_colliding():
		take_damage(Vector2(-600,-100))
	elif $ray_left.is_colliding():
		take_damage(Vector2(600,-100))
	elif $ray_up.is_colliding():
		take_damage(Vector2(0, -400))


func take_damage(knockback_force := Vector2.ZERO, duration:= 0.25):
	if invul_time_left > 0.0:
		return
	if Globals.player_life > 1:
		Globals.player_life -= 1
	else:
		queue_free()
		emit_signal("player_has_died")

	invul_time_left = invulnerability_time
	blink_time_left = 0.0 # força blink imediato
	animated_sprite.visible = true
	if knockback_force != Vector2.ZERO:
		knockback_vector = knockback_force
		var knockback_tween := get_tree().create_tween()
		knockback_tween.tween_property(self, "knockback_vector", Vector2.ZERO, duration)
		animated_sprite.modulate = Color(1, 0, 0, 1)
		knockback_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), duration)

