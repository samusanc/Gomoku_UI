extends RichTextLabel

## Live link indicator in the console view.

@onready var reconnect_button: Button = $"../Reconnect"


func _ready() -> void:
	bbcode_enabled = true
	text = "[color=lime]online[/color]"
	reconnect_button.disabled = true
	SignalBus.server_down.connect(server_down)


func server_down() -> void:
	text = "[color=red]offline[/color]"
	reconnect_button.disabled = false
