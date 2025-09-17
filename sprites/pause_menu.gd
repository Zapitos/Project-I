extends CanvasLayer
@onready var resume_btn: Button = $menu_holder/resume_btn
@onready var quit_btn: Button = $menu_holder/quit_btn


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true
		resume_btn.grab_focus()


func _on_resume_btn_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_quit_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://prefabricados/title_screen.tscn")
