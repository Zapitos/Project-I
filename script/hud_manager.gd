extends Control

@onready var life_counter: Label = $container/life_container/life_counter as Label


func _ready() -> void:
	life_counter.text = str("%01d" % Globals.player_life)
	
func _process(delta: float) -> void:
	life_counter.text = str("%01d" % Globals.player_life)
