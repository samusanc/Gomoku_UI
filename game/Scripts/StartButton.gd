extends ChunkyButton

## PLAY: asks for a connection using whatever endpoint Options holds.

func _on_pressed() -> void:
	SignalBus.hide_menu.emit()
	SignalBus.new_connection.emit(Settings.host, Settings.port)
