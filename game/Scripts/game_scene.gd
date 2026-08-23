extends Control

## Root of the playable scene. Owns the buttons that send commands and marks
## the scene ready so Network can flush anything it buffered while loading.
##
## It starts a game only when the server says there is none, so reconnecting
## mid-game resumes instead of wiping the position.



func _ready() -> void:
	SignalBus.command.connect(on_command)
	SignalBus.request_new_game.connect(new_game)
	# ask for the position; if there is no game yet we start one below
	Network.send_line("STATE")


func on_command(line: String) -> void:
	if line.begins_with("ERROR no_game"):
		new_game()


func new_game() -> void:
	Network.send_line(Settings.new_game_line())


func _on_hint_pressed() -> void:
	Network.send_line("SUGGEST")


func _on_rematch_pressed() -> void:
	new_game()


func _on_resign_pressed() -> void:
	Network.send_line("RESIGN")
