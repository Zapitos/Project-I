extends StaticBody2D


# Esta função é chamada quando algo entra na área de detecção
func _on_area_de_ativacao_body_entered(body: Node2D) -> void:
	# 1. Verifica se foi o jogador que entrou
	if body.is_in_group("player"):
		# 2. Se for o jogador, inicia o timer
		$Timer.start()
		# Bônus: Podemos adicionar um efeito visual para indicar que vai quebrar
		# Por exemplo, uma leve tremida ou mudança de cor (opcional)

# Esta função é chamada quando o tempo do Timer acaba
func _on_timer_timeout() -> void:
	# 3. Quando o tempo acaba, o chão se destrói
	queue_free()
	
