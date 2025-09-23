extends Area2D

@onready var collision: CollisionShape2D = $collision
@onready var spikes: Sprite2D = $spikes 


#faz automaticamente o tamanho da colisão dos espinhos independente de quantos
#lembrar de não mexer no tamanho do collision dos spikes pos não ira funcionar
#func _ready():
	#collision.shape.size = spikes.get_rect().size

#função de dano dos espinhos
func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" && body.has_method("take_damage"):
			body.take_damage(Vector2(0, -850)) #-850 distancia que player vai quando levar dano
	
