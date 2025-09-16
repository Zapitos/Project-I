extends Control

@onready var life_counter: Label = $container/life_container/life_counter as Label


func _ready() -> void:
	if Engine.has_singleton("Globals") or typeof(Globals) != TYPE_NIL:
		life_counter.text = str("%01d" % Globals.player_life)

func _process(_delta: float) -> void:
	if typeof(Globals) != TYPE_NIL:
		life_counter.text = str("%01d" % Globals.player_life)
