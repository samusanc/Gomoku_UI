extends AnimatedSprite2D

## Spinner shown while a connection attempt is in flight.
##
## It has to stop on BOTH outcomes. It used to hide only on
## stop_load_animation, which fires on failure, so a successful connect left it
## spinning for as long as the menu stayed up - and since the play flow now
## keeps the menu alive behind it, that was visible.

func start_load(_host = null, _port = null) -> void:
	visible = true
	play()


func stop_load(_reason = null) -> void:
	visible = false
	stop()


func _ready() -> void:
	visible = false
	SignalBus.new_connection.connect(start_load)
	# failure
	SignalBus.stop_load_animation.connect(stop_load)
	# success: the socket came up
	SignalBus.start_game.connect(stop_load)
	# and any way of leaving the connect screens
	SignalBus.hide_menu.connect(stop_load)
	SignalBus.leave_game.connect(stop_load)
