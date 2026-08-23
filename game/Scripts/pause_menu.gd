extends Control

## Overlay menu, opened and closed with ESC.
##
## It deliberately does NOT pause the scene tree. The server owns the game and
## keeps running whatever we do, so freezing our own process would only stall
## the socket read while the engine carried on thinking - the position would
## then arrive in a burst on resume. Instead this dims the board, swallows
## input so no stray click reaches the goban, and offers the actions that
## actually make sense mid game.

@onready var resume_button: Button = $Panel/Box/VBox/Resume
@onready var box: Control = $Panel
@onready var options: Control = $Options


func _ready() -> void:
	visible = false
	SignalBus.game_ended.connect(on_game_ended)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if event.keycode == KEY_ESCAPE and event.is_pressed() and not event.is_echo():
		toggle()
		accept_event()


func toggle() -> void:
	visible = not visible
	if visible:
		show_buttons()
		resume_button.grab_focus()


func show_buttons() -> void:
	box.visible = true
	options.visible = false


func _on_options_pressed() -> void:
	box.visible = false
	options.visible = true
	options.sync()


func _on_options_closed() -> void:
	show_buttons()


## When the game is over there is nothing to resume, so make that obvious.
func on_game_ended(_winner: String, _reason: String) -> void:
	resume_button.text = "Close"


func _on_resume_pressed() -> void:
	visible = false


func _on_rematch_pressed() -> void:
	visible = false
	resume_button.text = "Resume"
	SignalBus.request_new_game.emit()


func _on_resign_pressed() -> void:
	Network.send_line("RESIGN")
	visible = false


func _on_disconnect_pressed() -> void:
	visible = false
	SignalBus.leave_game.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()
