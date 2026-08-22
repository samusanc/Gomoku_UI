extends ChunkyButton

## PLAY: reads host and port out of the two fields and asks for a connection.

@onready var port_field: LineEdit = $"../Port"
@onready var host_field: LineEdit = $"../Host"

const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := "4242"


func _on_pressed() -> void:
	var host := DEFAULT_HOST
	var port := DEFAULT_PORT

	if host_field.text != "":
		host = host_field.text
	if port_field.text != "":
		port = port_field.text

	SignalBus.hide_menu.emit()
	SignalBus.new_connection.emit(host, port)
