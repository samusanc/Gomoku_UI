extends Node

## Player choices from the Options panel.
##
## Session only, nothing is written to disk. These are the parameters of the
## next NEW; they never affect a game already in progress, which is why the
## panel says so.

const MODE_AI := "pva"
const MODE_HOTSEAT := "pvp"

signal changed()

## Where to connect. Edited in Options, read by the play button, so moving the
## fields between screens does not touch the connect path.
var host := "127.0.0.1"
var port := "4242"

var mode := MODE_AI
var human_colour := "B"
var ruleset := "standard"


func set_mode(value: String) -> void:
	mode = value
	changed.emit()


func set_human_colour(value: String) -> void:
	human_colour = value
	changed.emit()


func set_ruleset(value: String) -> void:
	ruleset = value
	changed.emit()


func set_endpoint(new_host: String, new_port: String) -> void:
	if new_host != "":
		host = new_host
	if new_port != "":
		port = new_port
	changed.emit()


func is_hotseat() -> bool:
	return mode == MODE_HOTSEAT


## The NEW line the server expects. In hotseat there is no AI, so no colour is
## claimed by a human and the field is a dash.
func new_game_line() -> String:
	var human := human_colour
	if is_hotseat():
		human = "-"
	return "NEW %s %s %s" % [mode, ruleset, human]
