extends Control

## The [<] MODE [>] picker.
##
## The label slides out in the direction you pressed, swaps its text while it is
## off screen, then slides back in from the other side. Two tweens would fight
## each other on a fast double click, so the running one is killed first.
##
## The label sits inside a plain Control rather than directly in the HBox. A
## container rewrites its children positions on every layout pass, so animating
## the position of a direct child fights the container and leaves the text
## parked off centre. Inside a non container parent, x = 0 really is the rest
## position.

signal mode_changed(index)

const SLIDE := 90.0
const HALF_TIME := 0.11

@onready var label: Label = $Row/Slot/Label

var titles: Array[String] = []
var index := 0
var slide: Tween = null


func setup(names: Array[String], start := 0) -> void:
	titles = names
	index = clampi(start, 0, maxi(0, titles.size() - 1))
	label.text = current()


func current() -> String:
	if titles.is_empty():
		return ""
	return titles[index]


func _on_prev_pressed() -> void:
	step(-1)


func _on_next_pressed() -> void:
	step(1)


func step(direction: int) -> void:
	if titles.is_empty():
		return
	index = wrapi(index + direction, 0, titles.size())
	animate(direction)
	mode_changed.emit(index)


## Out one way, in from the other. The text changes at the midpoint so the old
## title is never seen moving back.
func animate(direction: int) -> void:
	if slide != null and slide.is_valid():
		slide.kill()
	var rest := 0.0
	label.position.x = rest
	label.modulate.a = 1.0
	slide = create_tween()
	slide.set_parallel(true)
	slide.tween_property(label, "position:x", -SLIDE * direction, HALF_TIME)
	slide.tween_property(label, "modulate:a", 0.0, HALF_TIME)
	slide.chain().tween_callback(apply_text)
	slide.chain().set_parallel(true)
	slide.tween_property(label, "position:x", rest, HALF_TIME)
	slide.tween_property(label, "modulate:a", 1.0, HALF_TIME)


func apply_text() -> void:
	label.text = current()
	# start the return leg from the far side
	label.position.x = SLIDE * signf(-label.position.x)
