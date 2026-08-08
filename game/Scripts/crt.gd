extends ColorRect

## Full screen CRT filter. Purely cosmetic, toggled from the menu.

func enable_crt() -> void:
	visible = true


func disable_crt() -> void:
	visible = false


func _ready() -> void:
	SignalBus.enable_crt.connect(enable_crt)
	SignalBus.disable_crt.connect(disable_crt)
	disable_crt()
