extends Node


var total_coins: int = 0

func coin_collected(value: int):
	total_coins += value
	EventController.emit_signal("coin_collected", total_coins)

# Reinicia a contagem de moedas (usado ao reiniciar fase ou voltar ao título)
func reset_coins():
	total_coins = 0
	EventController.emit_signal("coin_collected", total_coins)
