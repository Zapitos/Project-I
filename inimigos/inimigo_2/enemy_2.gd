extends CharacterBody2D


@export var hover_speed: float = 72.0
@export var base_dive_speed: float = 410.0 # velocidade base do mergulho (agressividade)
@export var aggro_radius: float = 300.0
@export var dive_prep_time: float = 0.85
@export var dive_cooldown: float = 1.8 # recuperação após mergulho
@export var dive_min_interval: float = 6.0 # intervalo mínimo entre mergulhos completos
@export var dive_total_time: float = 0.95 # duração alvo do mergulho (ajustar conforme velocidade)
@export var dive_trigger_horizontal: float = 170.0 # alcance horizontal p/ iniciar mergulho
@export var dive_trigger_vertical: float = 300.0 # tolerância vertical p/ iniciar mergulho
@export var show_debug := true
const DAMAGE := 1
const BLINK_TIME := 0.15

@onready var texture := $texture as Sprite2D
var vision: Area2D

enum State { HOVER, PREPARE_DIVE, DIVING, COOLDOWN }
var state: State = State.HOVER
var target: Node2D
var state_time := 0.0
var rest_since_last_dive := 6.0 # começa liberado para mergulhar cedo (>=6)
var dive_dir := Vector2.ZERO
var health := 3
var blinking := false
var direction := 1

var _player_in_sight := false

func _ready():
	add_to_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	vision = get_node_or_null("vision")
	if vision:
		vision.body_entered.connect(_on_vision_body_entered)
		vision.body_exited.connect(_on_vision_body_exited)

func _physics_process(delta: float) -> void:
	state_time += delta
	# Tempo de descanso só acumula fora do mergulho real e depois que ele terminou
	if state == State.HOVER:
		rest_since_last_dive += delta
	if show_debug:
		queue_redraw()
	match state:
		State.HOVER:
			_hover_logic(delta)
			if _can_start_dive() and rest_since_last_dive >= dive_min_interval:
				_change_state(State.PREPARE_DIVE)
		State.PREPARE_DIVE:
			if state_time >= dive_prep_time:
				_change_state(State.DIVING)
		State.DIVING:
			_dive_logic(delta)
			if state_time >= dive_total_time:
				_change_state(State.COOLDOWN)
		State.COOLDOWN:
			if state_time >= dive_cooldown:
				_change_state(State.HOVER)

	move_and_slide()

func _hover_logic(_delta):
	if not target:
		return
	var to_player = (target.global_position - global_position)
	if abs(to_player.x) > 6:
		direction = 1 if to_player.x > 0 else -1
	velocity.x = direction * hover_speed
	# voo pseudo-natural: mantém altitude alvo com ondulação senoidal
	var desired_y = target.global_position.y - 110
	var dy = desired_y - global_position.y
	var sinus := sin(Time.get_ticks_msec()/400.0) * 25
	velocity.y = clamp(dy * 1.4 + sinus, -120, 120)
	texture.flip_h = direction < 0

func _can_start_dive() -> bool:
	if not target or not _player_in_sight:
		return false
	var horiz = abs(target.global_position.x - global_position.x)
	var vert = abs(target.global_position.y - global_position.y)
	if horiz > aggro_radius or vert > dive_trigger_vertical:
		return false
	return horiz <= dive_trigger_horizontal

func _change_state(new_state: State):
	state = new_state
	state_time = 0.0
	if state == State.PREPARE_DIVE:
		velocity = Vector2.ZERO
	elif state == State.DIVING:
		# define direção do mergulho e zera tempo para easing
		if target:
			dive_dir = (target.global_position - global_position).normalized()
		else:
			dive_dir = Vector2(direction, 0).normalized()
		state_time = 0.0
		# velocidade inicial menor (easing acelera no meio)
		velocity = dive_dir * (base_dive_speed * 0.4)
	elif state == State.COOLDOWN:
			velocity = Vector2.ZERO
			rest_since_last_dive = 0.0 # mergulho acabou: começa a contar os 6s a partir daqui

func _dive_logic(_delta):
	# Easing: acelera até meio, mantém e desacelera final.
	var t: float = clamp(state_time / dive_total_time, 0.0, 1.0)
	# curva tipo sino: acelera forte no meio (sinus combinado)
	var speed_factor := 0.25 + sin(t * PI) # 0.25 a 1.25 aproximadamente
	velocity = dive_dir * (base_dive_speed * speed_factor)
	# Ajusta flip conforme direção horizontal do mergulho
	if abs(dive_dir.x) > 0.05:
		texture.flip_h = dive_dir.x < 0
	# colisão simples com jogador
	if target and global_position.distance_to(target.global_position) < 24:
		if target.has_method("take_damage"):
			var dir = 1 if target.global_position.x > global_position.x else -1
			target.take_damage(Vector2(dir*450,-150))
			_change_state(State.COOLDOWN)
	# encerra se passou muito abaixo do player (evita sumir para sempre)
	if target and global_position.y > target.global_position.y + 200:
		_change_state(State.COOLDOWN)

func _on_vision_body_entered(body):
	if body.is_in_group("player"):
		_player_in_sight = true
func _on_vision_body_exited(body):
	if body.is_in_group("player"):
		_player_in_sight = false

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

func _draw():
	if not show_debug:
		return
	# círculos de debug (apenas overlay translucido)
	var aggro_col = Color(0.2,0.6,1,0.25)
	var trig_col = Color(1,0.4,0.2,0.5)
	draw_circle(Vector2.ZERO, aggro_radius, aggro_col)
	draw_circle(Vector2.ZERO, dive_trigger_horizontal, trig_col)
	# linha direção mergulho
	if state == State.DIVING and dive_dir != Vector2.ZERO:
		draw_line(Vector2.ZERO, dive_dir * 120, Color(1,0.9,0.2,0.8), 2.0)
