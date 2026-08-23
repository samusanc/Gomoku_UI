extends VBoxContainer

## SCORE: captures for each side, each in a box the colour of the stone that
## took them, so you can read it without a legend.

@onready var white_count: Label = $Row/White/Count
@onready var black_count: Label = $Row/Black/Count


func _ready() -> void:
	SignalBus.captures_changed.connect(on_captures)
	SignalBus.game_started.connect(on_new_game)
	on_captures(0, 0)


func on_new_game(_mode: String, _ruleset: String, _first: String) -> void:
	on_captures(0, 0)


## The protocol counts stones, and ten of them wins, so that is what is shown.
func on_captures(black: int, white: int) -> void:
	white_count.text = str(white)
	black_count.text = str(black)
