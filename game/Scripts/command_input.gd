extends LineEdit

## Sends a raw protocol line to the server, so the link can be exercised by
## hand before the board exists. Try: STATE, NEW pvp standard -, MOVE 9 9.

func _ready() -> void:
	text_submitted.connect(on_submitted)


func on_submitted(line: String) -> void:
	var trimmed := line.strip_edges()
	if trimmed.is_empty():
		return
	SignalBus.new_message.emit("[color=#b6f5a1]>>[/color] " + trimmed.replace("[", "[lb]"))
	Network.send_line(trimmed)
	clear()
