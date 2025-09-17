extends Node2D

@export var value: int = 1
@onready var coin_sfx: AudioStreamPlayer = $coin_sfx as AudioStreamPlayer

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is player:
		GameController.coin_collected(value)
		coin_sfx.play()              # toca o som
		$Area2D.set_deferred("monitoring", false)
		hide()                       # esconde o visual da moeda
		await coin_sfx.finished      # espera o som terminar
		queue_free()                # agora sim remove o nó
