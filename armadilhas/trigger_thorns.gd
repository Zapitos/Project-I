extends Area2D

@export var espinhos: CharacterBody2D

func _on_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("player"):
		espinhos.ativar_queda()

func reset_armadilha():
	if espinhos != null:
		espinhos.reset()
