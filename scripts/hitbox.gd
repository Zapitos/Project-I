extends Area2D


func _on_body_entered(_body: Node2D) -> void:
	if _body.name == "player":
		print("colidiu")
		
