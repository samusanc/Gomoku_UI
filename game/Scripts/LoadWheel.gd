extends AnimatedSprite2D

## Spinner shown while a connection attempt is in flight.

func start_load(_host, _port) -> void:
	visible = true
	play()


func stop_load(_message) -> void:
	visible = false
	stop()


func _ready() -> void:
	visible = false
	SignalBus.new_connection.connect(start_load)
	SignalBus.stop_load_animation.connect(stop_load)
