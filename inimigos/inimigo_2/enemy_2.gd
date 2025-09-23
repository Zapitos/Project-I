extends CharacterBody2D


const HOVER_SPEED := 60.0
const DIVE_SPEED := 380.0
const AGGRO_RADIUS := 280.0
const DIVE_PREP_TIME := 0.6
const DIVE_COOLDOWN := 1.4
const DAMAGE := 1
const BLINK_TIME := 0.15

@onready var texture := $texture as Sprite2D

enum State { HOVER, PREPARE_DIVE, DIVING, COOLDOWN }
var state: State = State.HOVER
var target: Node2D
var state_time := 0.0
var health := 3
var blinking := false
var direction := 1

func _ready():
	add_to_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	state_time += delta
	match state:
		State.HOVER:
			_hover_logic(delta)
			if _can_start_dive():
				_change_state(State.PREPARE_DIVE)
		State.PREPARE_DIVE:
			if state_time >= DIVE_PREP_TIME:
				_change_state(State.DIVING)
		State.DIVING:
			_dive_logic(delta)
			if state_time >= 1.2:
				_change_state(State.COOLDOWN)
		State.COOLDOWN:
			if state_time >= DIVE_COOLDOWN:
				_change_state(State.HOVER)

	move_and_slide()

func _hover_logic(_delta):
	if not target:
		return
	var to_player = (target.global_position - global_position)
	if abs(to_player.x) > 6:
		direction = 1 if to_player.x > 0 else -1
	velocity.x = direction * HOVER_SPEED
	# ajusta altitude aproximada
	var desired_y = target.global_position.y - 90
	var dy = desired_y - global_position.y
	velocity.y = clamp(dy * 2, -80, 80)
	texture.flip_h = direction < 0

func _can_start_dive() -> bool:
	if not target:
		return false
	return global_position.distance_to(target.global_position) <= AGGRO_RADIUS

func _change_state(new_state: State):
	state = new_state
	state_time = 0.0
	if state == State.PREPARE_DIVE:
		velocity = Vector2.ZERO
	elif state == State.DIVING:
		# define direção do mergulho
		if target:
			var dir_vec = (target.global_position - global_position).normalized()
			velocity = dir_vec * DIVE_SPEED
	elif state == State.COOLDOWN:
		velocity = Vector2.ZERO

func _dive_logic(_delta):
	# colisão simples com jogador
	if target and global_position.distance_to(target.global_position) < 24:
		if target.has_method("take_damage"):
			var dir = 1 if target.global_position.x > global_position.x else -1
			target.take_damage(Vector2(dir*450,-150))
			_change_state(State.COOLDOWN)

func take_damage(amount := 1, _from_dir := 1):
	if blinking:
		return
	health -= amount
	_blink_feedback()
	if health <= 0:
		queue_free()
func _blink_feedback():
	blinking = true
	var tween = get_tree().create_tween()
	texture.modulate = Color(1,1,1,0.2)
	tween.tween_property(texture, "modulate", Color(1,1,1,1), BLINK_TIME)
	tween.finished.connect(func(): blinking = false)
