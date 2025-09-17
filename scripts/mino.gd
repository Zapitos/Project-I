extends CharacterBody2D  # Verifique se seu nó é desse tipo!

const BESPINHOS := preload("res://prefabricados/bespinhos.tscn")
const FIRE := preload("res://prefabricados/fire.tscn")
const SPEED = 15000.0
var direction = -1
@onready var wall_detector: RayCast2D = $wall_detector
@onready var textura: Sprite2D = $textura

@onready var fire_point: Marker2D = %fire_point
@onready var bespinhos_point: Marker2D = %Bespinhos_point




func _physics_process(delta: float) -> void:
	# Verifica colisão e inverte direção
	if wall_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1

	# Define a velocidade HORIZONTAL (preserva a velocidade vertical, ex: gravidade)
	velocity.x = direction * SPEED * delta

	# Atualiza a animação da textura
	if direction == 1:
		textura.flip_h = true
	else:
		textura.flip_h = false

	# Move o nó
	move_and_slide()
	
func throw_bespinhos():
	var bespinhos_instance = BESPINHOS.instantiate()
	add_sibling(bespinhos_instance)
	bespinhos_instance.global_position = bespinhos_point.global_position
	bespinhos_instance.apply_impulse(Vector2(randi_range(direction * 30, direction * 200), randi_range(-200,-400)))
	
	
	


func _on_bomb_cooldown_timeout() -> void:
	throw_bespinhos()
