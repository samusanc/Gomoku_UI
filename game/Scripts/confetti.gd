extends ColorRect

## Falling confetti for the result screen.
##
## The shader places particles in pixels, not UV, so it needs to be told how
## big the rect actually is. Left at its default 1920x1080 the pieces would be
## the wrong size and half of them would fall outside the view.
##
## It also only runs while visible: the loop is per pixel over every particle,
## which is not something to leave burning behind a hidden node.

func _ready() -> void:
	resized.connect(push_resolution)
	visibility_changed.connect(on_visibility)
	push_resolution()
	on_visibility()


func push_resolution() -> void:
	if material != null and size.x > 0.0 and size.y > 0.0:
		material.set_shader_parameter("resolution", size)


func on_visibility() -> void:
	set_process(is_visible_in_tree())
