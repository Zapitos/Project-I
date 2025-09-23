extends Area2D

var is_active = false
@onready var anim: AnimatedSprite2D = $anim


func _on_body_entered(_body: Node2D) -> void:
	if _body.name != "player" or is_active:
		return
	activate_checkpoint()

func activate_checkpoint():
	#Globals.current_checkpoint = self
	anim.play("raising")
	is_active = true


func _on_anim_animation_finished() -> void:
	if anim.animation == "raising":
		anim.play("checked")
