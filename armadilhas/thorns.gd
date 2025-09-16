extends CharacterBody2D

var is_falling = false
var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Só aplica a gravidade se a armadilha for ativada
	if is_falling:
		velocity.y += gravidade * delta
	
	move_and_slide()
	
	# Se a armadilha foi ativada e agora está no chão, chame o reset.
	if is_falling and is_on_floor():
		reset()
		
func ativar_queda():
	is_falling = true
	
var posicao_inicial: Vector2

func _ready():
	posicao_inicial = self.position
	
func reset():
	is_falling = false
	velocity = Vector2.ZERO
	position = posicao_inicial
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Verifica se o corpo que entrou no hitbox é o jogador
	if body.is_in_group("player"):
		# Ação de "game over" mais simples: recarregar a cena
		get_tree().reload_current_scene()
