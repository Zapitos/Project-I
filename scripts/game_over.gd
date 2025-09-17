extends Control

@onready var restart_btn: Button = $VBoxContainer/Restart_Btn
@onready var quit_btn: Button = $VBoxContainer/Quit_Btn

func _ready() -> void:
	restart_btn.grab_focus()

func _on_restart_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/niveis/test_level.tscn")




func _on_quit_btn_pressed() -> void:
		get_tree().change_scene_to_file("res://prefabricados/title_screen.tscn")
