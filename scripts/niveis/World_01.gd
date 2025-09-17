extends Node2D


@onready var player_node := $player as CharacterBody2D
#@onready var player_scene = preload("res://personagem/player.tscn")
@onready var camera := $camera as Camera2D

func _ready() -> void:
	player_node.follow_camera(camera)
	player_node.player_has_died.connect(reload_game)
	Globals.player_life = 2

func reload_game():
	await get_tree().create_timer(1.0).timeout
	#var player = player_scene.instantiate()
	#add_child(player)
	#Globals.player = player
	#Globals.respaw_player()
	get_tree().change_scene_to_file("res://prefabricados/game_over.tscn")
