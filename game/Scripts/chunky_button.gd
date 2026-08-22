@tool
class_name ChunkyButton
extends Button

## The one menu button in the game: chunky white text with a hard shadow, on a
## flat face with a hard shadow of its own. Every menu button is either an
## instance of Scenes/UI/ChunkyButton.tscn or a script that extends this, so the
## look lives in exactly one place.
##
## The face shadow is a StyleBoxFlat shadow, which Godot draws as a solid shape
## with no blur. Setting shadow_size equal to the offset makes it sit flush with
## the top-left edge and spill only down and right, so it reads as a plain drop
## shadow rather than a glow.
##
## The caption is drawn by a child Label, not by the Button. Button exposes only
## an outline in its theme, it has no text shadow at all, while Label has both.
## So the Button keeps its text purely to size itself, paints it transparent,
## and the Label on top does the visible drawing.
##
## Named ChunkyButton, not MenuButton: that one is a built-in Godot class.

enum Tone {GO, NEUTRAL, BAD}

const CAPTION_NAME := "Caption"

const SHADOW_STEP := 3
const CORNER := 6
const BORDER := 2

const SHADOW_COLOUR := Color(0.0, 0.0, 0.0, 0.85)
const TEXT_SHADOW_COLOUR := Color(0.0, 0.0, 0.0, 0.9)
const TEXT_SHADOW_OFFSET := 2
const TEXT_COLOUR := Color(0.97, 0.98, 1.0)
const OUTLINE_COLOUR := Color(1.0, 1.0, 1.0)
const CLEAR := Color(0, 0, 0, 0)

## normal, hover, pressed -> [face, border]
const TONES := {
	Tone.GO: [
		[Color(0.129, 0.447, 0.243), Color(0.353, 0.804, 0.455)],
		[Color(0.180, 0.580, 0.302), Color(0.482, 0.910, 0.565)],
		[Color(0.086, 0.318, 0.173), Color(0.353, 0.804, 0.455)],
	],
	Tone.NEUTRAL: [
		[Color(0.141, 0.278, 0.447), Color(0.400, 0.600, 0.850)],
		[Color(0.192, 0.373, 0.580), Color(0.541, 0.722, 0.929)],
		[Color(0.098, 0.200, 0.329), Color(0.400, 0.600, 0.850)],
	],
	Tone.BAD: [
		[Color(0.502, 0.149, 0.149), Color(0.850, 0.400, 0.400)],
		[Color(0.631, 0.204, 0.204), Color(0.929, 0.541, 0.541)],
		[Color(0.357, 0.102, 0.102), Color(0.850, 0.400, 0.400)],
	],
}

@export var tone: Tone = Tone.NEUTRAL:
	set(value):
		tone = value
		restyle()

@export var chunk_size := 24:
	set(value):
		chunk_size = value
		restyle()

## Thickness of the white text outline.
@export var outline_thickness := 2:
	set(value):
		outline_thickness = value
		restyle()

## Inner padding. Small utility buttons want less than menu buttons, so it is
## a property rather than a constant.
@export var pad := Vector2i(18, 9):
	set(value):
		pad = value
		restyle()

var caption: Label = null


func _ready() -> void:
	restyle()


## The caption has to follow `text`, which Button gives no signal for, and dim
## itself when the button is disabled.
func _process(_delta: float) -> void:
	if caption == null or not is_instance_valid(caption):
		return
	if caption.text != text:
		caption.text = text
	var wanted := 0.45 if disabled else 1.0
	if not is_equal_approx(caption.modulate.a, wanted):
		caption.modulate.a = wanted


func ensure_caption() -> void:
	if caption == null or not is_instance_valid(caption):
		caption = get_node_or_null(NodePath(CAPTION_NAME)) as Label
	if caption == null:
		caption = Label.new()
		caption.name = CAPTION_NAME
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func make_box(face: Color, border: Color, sunken: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()

	box.bg_color = face
	box.border_color = border
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(CORNER)
	# hard edges, to sit with the pixel font and the pixel art title
	box.anti_aliasing = false
	box.content_margin_left = pad.x
	box.content_margin_right = pad.x
	box.content_margin_top = pad.y
	box.content_margin_bottom = pad.y
	box.shadow_color = SHADOW_COLOUR
	# equal size and offset: flush at top-left, solid block at bottom-right
	var step := 1 if sunken else SHADOW_STEP
	box.shadow_size = step
	box.shadow_offset = Vector2(step, step)
	return box


func flat_box(face: Color, border: Color) -> StyleBoxFlat:
	var box := make_box(face, border, false)
	box.shadow_size = 0
	box.shadow_offset = Vector2.ZERO
	return box


func style_caption() -> void:
	ensure_caption()
	caption.text = text
	caption.add_theme_font_size_override("font_size", chunk_size)
	caption.add_theme_color_override("font_color", TEXT_COLOUR)
	caption.add_theme_color_override("font_outline_color", OUTLINE_COLOUR)
	caption.add_theme_constant_override("outline_size", outline_thickness)
	caption.add_theme_color_override("font_shadow_color", TEXT_SHADOW_COLOUR)
	caption.add_theme_constant_override("shadow_offset_x", TEXT_SHADOW_OFFSET)
	caption.add_theme_constant_override("shadow_offset_y", TEXT_SHADOW_OFFSET)
	# 0 keeps the shadow the same shape as the glyph, so it stays a plain
	# offset copy instead of growing a halo
	caption.add_theme_constant_override("shadow_outline_size", 0)


## The Button still needs `text` so it can size itself, it just must not paint
## it: the caption does that.
func hide_own_text() -> void:
	for slot in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color", "font_disabled_color", "font_outline_color",
			"font_hover_pressed_color"]:
		add_theme_color_override(slot, CLEAR)
	add_theme_constant_override("outline_size", 0)


func restyle() -> void:
	var set_of := TONES[tone] as Array

	add_theme_stylebox_override("normal", make_box(set_of[0][0], set_of[0][1], false))
	add_theme_stylebox_override("hover", make_box(set_of[1][0], set_of[1][1], false))
	# pressed: the shadow collapses, so the face looks like it sank into it
	add_theme_stylebox_override("pressed", make_box(set_of[2][0], set_of[2][1], true))
	add_theme_stylebox_override("focus", make_box(set_of[1][0], set_of[1][1], false))
	add_theme_stylebox_override("disabled",
		flat_box(Color(0.14, 0.15, 0.17, 0.9), Color(0.42, 0.44, 0.47, 0.45)))

	add_theme_font_size_override("font_size", chunk_size)
	hide_own_text()
	style_caption()
