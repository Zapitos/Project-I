extends Control


@onready var start_btn: Button = $MarginContainer/HBoxContainer/VBoxContainer/start_btn
@onready var credits_btn: Button = $MarginContainer/HBoxContainer/VBoxContainer/credits_btn
@onready var quit_btn: Button = $MarginContainer/HBoxContainer/VBoxContainer/quit_btn


func _ready() -> void:
	start_btn.grab_focus()

func _on_start_btn_pressed() -> void:
	# Reseta estado global antes de iniciar o jogo
	if typeof(GameController) != TYPE_NIL and GameController.has_method("reset_coins"):
		GameController.reset_coins()
	if typeof(Globals) != TYPE_NIL and Globals.has_method("reset"):
		Globals.reset()
	get_tree().change_scene_to_file("res://estagiotestes/test_level.tscn")


func _on_credits_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


