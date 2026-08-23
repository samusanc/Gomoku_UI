extends ColorRect

## Mask wipe between screens.
##
## The shader keeps a pixel opaque while the mask luminance under it is above
## the cutoff, so sweeping the cutoff from 1 to 0 paints the curtain on in the
## order the mask says, and 0 to 1 takes it off again. Idle it hides itself so
## it can never eat a click.

const PARAM := "luminance_cutoff"

@export var seconds := 0.45


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_cut(1.0)


func set_cut(value: float) -> void:
	if material != null:
		material.set_shader_parameter(PARAM, value)


## Paint the curtain on, ending fully covered.
func cover() -> void:
	visible = true
	var sweep := create_tween()
	sweep.tween_method(set_cut, 1.0, 0.0, seconds)
	await sweep.finished


## Take it off again, ending hidden.
func reveal() -> void:
	visible = true
	var sweep := create_tween()
	sweep.tween_method(set_cut, 0.0, 1.0, seconds)
	await sweep.finished
	visible = false
