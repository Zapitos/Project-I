extends Node2D


func reiniciar_nivel():
	# # Pega todos os nós no grupo "armadilhas"
	var todas_as_armadilhas = get_tree().get_nodes_in_group("armadilhas")
	for armadilha in todas_as_armadilhas:
		armadilha.reset_armadilha()
