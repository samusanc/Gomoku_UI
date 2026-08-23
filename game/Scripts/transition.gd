extends ColorRect

## Mask wipe between screens.
##
## The shader keeps a pixel opaque while the mask luminance under it is above
## the cutoff, so sweeping the cutoff from 1 to 0 paints the curtain on in the
## order the mask says, and 0 to 1 takes it off again. Idle it hides itself so
## it can never eat a click.

const PARAM := "luminance_cutoff"

## A different mask each time, cycled in order so consecutive transitions never
## repeat. The mask is chosen when the curtain goes on and kept for the matching
## reveal, so one transition is always a single effect.
const MASKS: Array[Texture2D] = [
	preload("res://Assets/Textures/swirl.png"),
	preload("res://Assets/Textures/transition_geometric.png"),
	preload("res://Assets/Textures/transition_puzzle.png"),
	preload("res://Assets/Textures/transition_noise.png"),
]

@export var seconds := 0.45

var mask_index := -1


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_cut(1.0)


func set_cut(value: float) -> void:
	if material != null:
		material.set_shader_parameter(PARAM, value)


func next_mask() -> void:
	if material == null or MASKS.is_empty():
		return
	mask_index = (mask_index + 1) % MASKS.size()
	material.set_shader_parameter("mask_texture", MASKS[mask_index])


## Paint the curtain on, ending fully covered.
func cover() -> void:
	next_mask()
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
