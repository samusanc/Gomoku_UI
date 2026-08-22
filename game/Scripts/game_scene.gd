extends Control

## Root of the playable scene. Owns the buttons that send commands and marks
## the scene ready so Network can flush anything it buffered while loading.
##
## It starts a game only when the server says there is none, so reconnecting
## mid-game resumes instead of wiping the position.

const DEFAULT_MODE := "pva"
const DEFAULT_RULESET := "standard"
const DEFAULT_HUMAN := "B"


func _ready() -> void:
	SignalBus.command.connect(on_command)
	SignalBus.SceneLoaded = true
	# ask for the position; if there is no game yet we start one below
	Network.send_line("STATE")


func on_command(line: String) -> void:
	if line.begins_with("ERROR no_game"):
		new_game()


func new_game() -> void:
	var mode := GameState.mode if GameState.mode != "" else DEFAULT_MODE
	var ruleset := GameState.ruleset if GameState.ruleset != "" \
		else DEFAULT_RULESET
	var human := DEFAULT_HUMAN
	if mode == "pvp":
		human = "-"
	elif GameState.ai_side == "B":
		human = "W"
	Network.send_line("NEW %s %s %s" % [mode, ruleset, human])


func _on_hint_pressed() -> void:
	Network.send_line("SUGGEST")


func _on_rematch_pressed() -> void:
	new_game()


func _on_resign_pressed() -> void:
	Network.send_line("RESIGN")
