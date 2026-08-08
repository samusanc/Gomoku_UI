extends RichTextLabel

## Shows why the last connection attempt failed, back on the menu.

func _ready() -> void:
	bbcode_enabled = true
	text = ""
	SignalBus.stop_load_animation.connect(show_error)
	SignalBus.new_connection.connect(clear_error)


func show_error(message) -> void:
	text = "[color=red]%s[/color]" % str(message)


func clear_error(_host, _port) -> void:
	text = ""
