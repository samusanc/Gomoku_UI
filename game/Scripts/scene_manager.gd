extends Node

## Swaps the menu out for the console view once the socket is up.

func start() -> void:
	get_tree().change_scene_to_file("res://Scenes/ConsoleScene.tscn")


func _ready() -> void:
	SignalBus.start_game.connect(start)
