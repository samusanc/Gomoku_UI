extends Control

## Idle float: a slow bob with a touch of sway, so a thing never looks frozen.
## Used by the menu logo and the result panel.
##
## Attach it to a node whose parent is NOT a container. Containers rewrite their
## children positions every layout pass, so a position animation on a direct
## child of one fights the container and drifts. Where the target has to live in
## a container, wrap it in a plain Control and float the wrapper.

@export var bob_pixels := 12.0
@export var bob_speed := 1.1
@export var tilt_degrees := 0.7
@export var tilt_speed := 0.55

var base_position := Vector2.ZERO
var elapsed := 0.0


func _ready() -> void:
	base_position = position


func _process(delta: float) -> void:
	elapsed += delta
	# recomputed rather than cached: size is still zero during _ready for an
	# anchored control, which would leave the tilt pivoting off a corner
	pivot_offset = size / 2.0
	position.y = base_position.y + sin(elapsed * bob_speed) * bob_pixels
	rotation_degrees = sin(elapsed * tilt_speed) * tilt_degrees
