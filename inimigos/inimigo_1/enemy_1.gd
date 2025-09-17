extends CharacterBody2D

const SPEED = 9000.0
const JUMP_VELOCITY = -400.0

@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D
@onready var ledge_detector := $ledge_detector as RayCast2D
@onready var hurtbox = $hurtbox  # Assuming the hurtbox is an Area2D node

var direction := 1
var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Connect the hurtbox's area_entered signal
	hurtbox.connect("area_entered", _on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if wall_detector.is_colliding() or not ledge_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1
		ledge_detector.scale.x *= -1
		
	if direction == 1:
		texture.flip_h = false
	else:
		texture.flip_h = true

	velocity.x = direction * SPEED * delta
	move_and_slide()

func _on_hurtbox_area_entered(area: Area2D):
	# Check if the area is from the player's attack
	if area.is_in_group("player_attack"):
		take_damage()

func take_damage():
	# Implement enemy taking damage (e.g., reduce health, die, etc.)
	queue_free()  # For now, just remove the enemy
