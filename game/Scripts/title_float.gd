extends TextureRect

## Idle float for the menu logo: a slow bob with a touch of sway, so the title
## never looks frozen. Purely cosmetic.

@export var bob_pixels := 12.0
@export var bob_speed := 1.1
@export var tilt_degrees := 0.7
@export var tilt_speed := 0.55

var base_position := Vector2.ZERO
var elapsed := 0.0


func _ready() -> void:
	base_position = position
	pivot_offset = size / 2.0


func _process(delta: float) -> void:
	elapsed += delta
	position.y = base_position.y + sin(elapsed * bob_speed) * bob_pixels
	rotation_degrees = sin(elapsed * tilt_speed) * tilt_degrees
