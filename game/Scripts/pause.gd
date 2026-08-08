extends Control

## ESC brings the menu back over the console view.

func hide_menu() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.is_pressed():
			visible = not visible


func _ready() -> void:
	visible = false
	SignalBus.hide_menu.connect(hide_menu)
