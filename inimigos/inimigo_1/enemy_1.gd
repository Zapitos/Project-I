extends CharacterBody2D

const SPEED = 130.0
const ATTACK_RANGE := 30.0
const ATTACK_COOLDOWN := 0.8
const DAMAGE := 1
const KNOCKBACK := Vector2(180, -120)
const BLINK_TIME := 0.15

@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D
@onready var ledge_detector := $ledge_detector as RayCast2D
@onready var hurtbox = $hurtbox
var vision: Area2D
var floor_probe: RayCast2D

var direction := 1
var target: Node2D
var attack_cooldown_left := 0.0
var health := 3
var blinking := false
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	add_to_group("enemy")
	hurtbox.connect("area_entered", _on_hurtbox_area_entered)
	# tenta achar player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	vision = get_node_or_null("vision")
	floor_probe = get_node_or_null("floor_probe")
	if vision:
		vision.body_entered.connect(_on_vision_body_entered)
		vision.body_exited.connect(_on_vision_body_exited)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta

	if target and _player_in_sight:
		var dist_x = target.global_position.x - global_position.x
		if abs(dist_x) > 4:
			var desired_dir = 1 if dist_x > 0 else -1
			# Verifica se há chão à frente antes de mudar/andar
			if floor_probe:
				floor_probe.position.x = 12 * desired_dir
				floor_probe.force_raycast_update()
				if floor_probe.is_colliding():
					direction = desired_dir
			else:
				direction = desired_dir
	else:
		if wall_detector.is_colliding() or not ledge_detector.is_colliding():
			direction *= -1
			wall_detector.scale.x *= -1
			ledge_detector.scale.x *= -1

	if direction == 1:
		texture.flip_h = false
	else:
		texture.flip_h = true

	velocity.x = direction * SPEED
	move_and_slide()

	if target and _can_attack_target():
		_perform_attack()

func _on_hurtbox_area_entered(area: Area2D):
	# Check if the area is from the player's attack
	if area.is_in_group("player_attack"):
		take_damage()

func take_damage(amount := 1, from_dir := 1):
	if blinking:
		return
	health -= amount
	_blink_feedback()
	if health <= 0:
		queue_free()
	else:
		# knockback simples
		velocity.x = -from_dir * KNOCKBACK.x
		velocity.y = KNOCKBACK.y

func _blink_feedback():
	blinking = true
	var tween = get_tree().create_tween()
	texture.modulate = Color(1,1,1,0.2)
	tween.tween_property(texture, "modulate", Color(1,1,1,1), BLINK_TIME)
	tween.finished.connect(func(): blinking = false)

func _can_attack_target() -> bool:
	if not target or attack_cooldown_left > 0.0 or not _player_in_sight:
		return false
	return abs(target.global_position.x - global_position.x) <= ATTACK_RANGE and abs(target.global_position.y - global_position.y) < 40

var _player_in_sight := false
func _on_vision_body_entered(body):
	if body.is_in_group("player"):
		_player_in_sight = true
func _on_vision_body_exited(body):
	if body.is_in_group("player"):
		_player_in_sight = false

func _perform_attack():
	attack_cooldown_left = ATTACK_COOLDOWN
	if target and target.has_method("take_damage"):
		var dir = 1 if target.global_position.x > global_position.x else -1
		target.take_damage(Vector2(dir*400,-200))
