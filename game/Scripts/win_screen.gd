extends Control

## Result overlay. Shows who won and how, with the stone of the winning colour.
## Draw (no winner) still uses this, with the stone hidden.
##
## The panel sits inside a Float wrapper that carries the same idle bob as the
## menu logo. The wrapper is sized to the panel rather than the screen so the
## sway pivots about the panel centre.

const STONE_BLACK := preload("res://Assets/Textures/stone_black.png")
const STONE_WHITE := preload("res://Assets/Textures/stone_white.png")

@onready var headline: Label = $Float/Box/VBox/Headline
@onready var reason_label: Label = $Float/Box/VBox/Reason
@onready var stone: TextureRect = $Float/Box/VBox/Stone


func _ready() -> void:
	visible = false
	SignalBus.game_ended.connect(on_game_ended)
	SignalBus.game_started.connect(on_game_started)


func on_game_started(_mode: String, _ruleset: String, _first: String) -> void:
	visible = false


func on_game_ended(winner: String, reason: String) -> void:
	if winner == "B":
		headline.text = "BLACK WIN!"
		stone.texture = STONE_BLACK
		stone.visible = true
	elif winner == "W":
		headline.text = "WHITE WIN!"
		stone.texture = STONE_WHITE
		stone.visible = true
	else:
		headline.text = "DRAW"
		stone.visible = false
	reason_label.text = "by %s" % reason
	visible = true


func _on_menu_pressed() -> void:
	visible = false
	SignalBus.leave_game.emit()


func _on_rematch_pressed() -> void:
	visible = false
	SignalBus.request_new_game.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()
