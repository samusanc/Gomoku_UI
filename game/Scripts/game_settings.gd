extends VBoxContainer

## The three game parameters. Lives wherever a game is about to be started, so
## it is a scene of its own rather than being welded into one menu.
##
## It only writes to Settings; nothing here talks to the server.

const MODES := [Settings.MODE_AI, Settings.MODE_HOTSEAT]
const COLOURS := ["B", "W"]

@onready var mode_pick: OptionButton = $Mode/Pick
@onready var colour_pick: OptionButton = $Colour/Pick
@onready var ruleset_pick: OptionButton = $Ruleset/Pick
@onready var note: Label = $Note


func _ready() -> void:
	mode_pick.clear()
	mode_pick.add_item("Human vs AI")
	mode_pick.add_item("Hotseat, two players")

	colour_pick.clear()
	colour_pick.add_item("Black, plays first")
	colour_pick.add_item("White, plays second")

	# The engine has no alternative rulesets yet, so offering them would be a
	# lie. The dropdown exists for when it does.
	ruleset_pick.clear()
	ruleset_pick.add_item("Standard")

	mode_pick.item_selected.connect(on_mode_selected)
	colour_pick.item_selected.connect(on_colour_selected)
	sync()


func sync() -> void:
	mode_pick.selected = MODES.find(Settings.mode)
	colour_pick.selected = COLOURS.find(Settings.human_colour)
	ruleset_pick.selected = 0
	colour_pick.disabled = Settings.is_hotseat()
	if Settings.is_hotseat():
		note.text = "Both players share the mouse. Hint suggests a move for whoever is on turn."
	else:
		note.text = "You play the colour chosen above."


func on_mode_selected(index: int) -> void:
	Settings.set_mode(MODES[index])
	sync()


func on_colour_selected(index: int) -> void:
	Settings.set_human_colour(COLOURS[index])
	sync()
