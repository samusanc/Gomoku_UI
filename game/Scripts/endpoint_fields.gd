extends VBoxContainer

## Host and port entry. Writes straight into Settings so the play button never
## has to know which screen these fields live on.

@onready var host_field: LineEdit = $Host/Field
@onready var port_field: LineEdit = $Port/Field


func _ready() -> void:
	host_field.text = Settings.host
	port_field.text = Settings.port
	host_field.text_changed.connect(on_changed)
	port_field.text_changed.connect(on_changed)


func on_changed(_text: String) -> void:
	Settings.set_endpoint(host_field.text, port_field.text)
