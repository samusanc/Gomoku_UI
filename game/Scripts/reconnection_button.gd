extends ChunkyButton

## Re-runs the last connection with the same host and port.

func _on_pressed() -> void:
	disabled = true
	SignalBus.new_message.emit("[color=gray]-- reconnecting --[/color]")
	SignalBus.retry_connection.emit()
