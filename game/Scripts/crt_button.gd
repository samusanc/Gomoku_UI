extends Button

## Toggles the CRT filter. Currently disabled in the scene: the filter is on
## from launch and not meant to be switched off, so the label starts in the
## "would turn it off" state to stay truthful if the button is re-enabled.

var crt_on := true


func _ready() -> void:
	text = "Disable CRT mode" if crt_on else "Enable CRT mode"


func _on_pressed() -> void:
	crt_on = not crt_on
	if crt_on:
		SignalBus.enable_crt.emit()
		text = "Disable CRT mode"
	else:
		SignalBus.disable_crt.emit()
		text = "Enable CRT mode"
