extends HBoxContainer

## Two stone buttons. The chosen one turns green and the other goes neutral,
## which is the whole selection indicator.

@onready var black_button: Button = $Black/Pick
@onready var white_button: Button = $White/Pick


func _ready() -> void:
	black_button.pressed.connect(choose.bind("B"))
	white_button.pressed.connect(choose.bind("W"))
	refresh()


func choose(colour: String) -> void:
	Settings.set_human_colour(colour)
	refresh()


func refresh() -> void:
	var black_on := Settings.human_colour == "B"
	black_button.tone = ChunkyButton.Tone.GO if black_on \
		else ChunkyButton.Tone.NEUTRAL
	white_button.tone = ChunkyButton.Tone.NEUTRAL if black_on \
		else ChunkyButton.Tone.GO
