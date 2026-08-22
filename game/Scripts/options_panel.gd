extends Control

## Display options. The game parameters used to live here, but they belong next
## to the button that starts a game, so they moved to the play panel.
##
## Whoever hosts this decides what "back" means, so Back is reported as a
## signal rather than acted on here.

signal closed()


## Kept so hosts can refresh before showing the panel; there is nothing to
## re-read yet, but the CRT toggle keeps its own label in sync.
func sync() -> void:
	pass


func _on_back_pressed() -> void:
	closed.emit()
