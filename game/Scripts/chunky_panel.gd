@tool
class_name ChunkyPanel
extends PanelContainer

## A ChunkyButton face with nothing clickable about it: same flat fill, border,
## corner and hard offset shadow. For grouping readouts so the side menu looks
## built from the same parts as the buttons.

const CORNER := 6
const BORDER := 2
const SHADOW_STEP := 3
const SHADOW_COLOUR := Color(0.0, 0.0, 0.0, 0.85)

@export var face := Color(0.055, 0.075, 0.105, 0.92):
	set(value):
		face = value
		restyle()

@export var edge := Color(0.400, 0.600, 0.850, 0.55):
	set(value):
		edge = value
		restyle()

@export var pad := Vector2i(14, 10):
	set(value):
		pad = value
		restyle()


func _ready() -> void:
	restyle()


func restyle() -> void:
	var box := StyleBoxFlat.new()

	box.bg_color = face
	box.border_color = edge
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	box.anti_aliasing = false
	box.content_margin_left = pad.x
	box.content_margin_right = pad.x
	box.content_margin_top = pad.y
	box.content_margin_bottom = pad.y
	box.shadow_color = SHADOW_COLOUR
	box.shadow_size = SHADOW_STEP
	box.shadow_offset = Vector2(SHADOW_STEP, SHADOW_STEP)
	add_theme_stylebox_override("panel", box)
