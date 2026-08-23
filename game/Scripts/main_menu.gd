extends Control

## Menu router. The start bar at the bottom swaps itself out for one of the
## panels; every panel has a Back that brings the bar back.

@onready var start_bar: Control = $StartMenu
@onready var play_flow: Control = $PlayFlow
@onready var options_panel: Control = $OptionsPanel


func _ready() -> void:
	play_flow.closed.connect(show_start)
	show_start()


func show_start() -> void:
	start_bar.visible = true
	play_flow.visible = false
	options_panel.visible = false


func _on_play_pressed() -> void:
	start_bar.visible = false
	options_panel.visible = false
	play_flow.visible = true


func _on_options_pressed() -> void:
	start_bar.visible = false
	play_flow.visible = false
	options_panel.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	show_start()
