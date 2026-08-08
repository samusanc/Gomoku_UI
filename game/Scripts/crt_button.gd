extends Button

## Toggles the CRT filter.

var crt_on := false


func _on_pressed() -> void:
	crt_on = not crt_on
	if crt_on:
		SignalBus.enable_crt.emit()
		text = "Disable CRT mode"
	else:
		SignalBus.disable_crt.emit()
		text = "Enable CRT mode"
