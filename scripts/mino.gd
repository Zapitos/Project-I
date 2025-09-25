extends CharacterBody2D  # Verifique se seu nó é desse tipo!

const BESPINHOS := preload("res://prefabricados/bespinhos.tscn")
const FIRE := preload("res://prefabricados/fire.tscn")
const SPEED = 13000.0
var direction = -1
@onready var wall_detector: RayCast2D = $wall_detector
@onready var sprite: Sprite2D = $sprite
@onready var attack_sprite: Sprite2D = $Sprite2D # Referência para a sprite de ataque


@onready var fire_point: Marker2D = %fire_point
@onready var bespinhos_point: Marker2D = %bespinhos_point

@onready var hurtbox: Area2D = $hurtbox
@onready var anim_tree: AnimationTree = $anim_tree
@onready var state_machine = anim_tree["parameters/playback"]

#Flags para estados do boss
var	turn_count := 0
var fire_count := 0
var bespinhos_count := 0
var can_launch_fire := true
var can_launch_bespinhos := true

var health := 7 # Vida do chefe
var blinking := false
const BLINK_TIME := 0.15





func _ready() -> void:
	# Adiciona o chefe ao grupo "enemy" para ser detectado pelos ataques do jogador
	add_to_group("enemy")
	set_physics_process(false)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)



func _physics_process(delta: float) -> void:
	# Verifica colisão e inverte direção
	if wall_detector.is_colliding():
		direction *= -1
		wall_detector.scale.x *= -1
		turn_count += 1
		

	match state_machine.get_current_node():
		"moving":
			sprite.visible = true
			attack_sprite.visible = false
			if direction == 1:
				velocity.x = SPEED * delta
				sprite.flip_h = true
			else:
				velocity.x = -SPEED * delta
				sprite.flip_h = false
		"fire_attack":
			sprite.visible = false
			attack_sprite.visible = true
			attack_sprite.flip_h = sprite.flip_h # Garante que a direção esteja correta
			velocity.x = 0
			await get_tree().create_timer(2.0).timeout
			if can_launch_fire:
				launch_fire()
				can_launch_fire = false
		"hide_bespinhos":
			velocity.x = 0
			sprite.visible = true
			attack_sprite.visible = false
			await get_tree().create_timer(2.0).timeout
			if can_launch_bespinhos:
				throw_bespinhos()
				can_launch_bespinhos = false
	
	if turn_count <= 2:
		anim_tree.set("parameters/conditions/can_move", true)
		anim_tree.set("parameters/conditions/time_fire", false)
	elif fire_count >= 2:
		anim_tree.set("parameters/conditions/time_bespinhos", true)
		fire_count = 0
	else:
		anim_tree.set("parameters/conditions/can_move", false)
		anim_tree.set("parameters/conditions/time_bespinhos", false)
		anim_tree.set("parameters/conditions/time_fire", true)



	# Move o nó
	move_and_slide()
	
func throw_bespinhos():
	if bespinhos_count <= 4:
		var bespinhos_instance = BESPINHOS.instantiate()
		add_sibling(bespinhos_instance)
		bespinhos_instance.global_position = bespinhos_point.global_position
		bespinhos_instance.apply_impulse(Vector2(randi_range(direction * 30, direction * 200), randi_range(-200,-400)))
		$bespinhos_cooldown.start()
		bespinhos_count += 1
	else:
		# Reinicia o ciclo de comportamento do chefe para que ele volte a se mover
		turn_count = 0
		bespinhos_count = 0
		


func launch_fire():
	if fire_count <= 2:
		var fire_instance: = FIRE.instantiate()
		add_sibling(fire_instance)
		fire_instance.global_position = fire_point.global_position
		fire_instance.set_direction(direction)
		$fire_cooldown.start()
		fire_count += 1


func take_damage(amount := 1, from_dir := 1):
	if blinking:
		return
	health -= amount
	_blink_feedback()
	if health <= 0:
		# Adicione aqui o que acontece quando o chefe morre (ex: explosão, som, etc)
		queue_free() # Destrói o nó do chefe


func _blink_feedback():
	blinking = true
	var tween = get_tree().create_tween()
	# Faz a sprite piscar em vermelho para indicar dano
	sprite.modulate = Color(1, 0.5, 0.5, 0.5)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), BLINK_TIME)
	# Garante que o estado 'blinking' seja resetado ao final da animação
	tween.finished.connect(func(): blinking = false)

func _on_hurtbox_area_entered(area: Area2D):
	# Verifica se a área que entrou pertence ao grupo de ataque do jogador
	if area.is_in_group("player_attack"):
		var player_dir = 1 if global_position.x < get_parent().get_node("player").global_position.x else -1
		take_damage(1, player_dir)


func _on_bespinhos_cooldown_timeout() -> void:
	can_launch_bespinhos = true
	

	

func _on_fire_cooldown_timeout() -> void:
	can_launch_fire = true


func _on_player_detector_body_entered(body: Node2D) -> void:
	set_physics_process(true)


func _on_visible_on_screen_enabler_2d_screen_entered() -> void:
	set_physics_process(true)
