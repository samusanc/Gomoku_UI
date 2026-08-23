extends VBoxContainer

## Who is playing, in turn order.
##
## The top row is whoever is on turn; the row under it is everybody else in the
## order they will play. When the turn advances the list rotates, so the strip
## reads as a queue moving left: the same cycling idea as the mode picker, laid
## out horizontally.

const ICON_HUMAN := preload("res://Assets/Textures/icon_human.png")
const ICON_BOT := preload("res://Assets/Textures/icon_bot.png")
const STONE_BLACK := preload("res://Assets/Textures/stone_black.png")
const STONE_WHITE := preload("res://Assets/Textures/stone_white.png")

const SLIDE := 46.0
const SLIDE_TIME := 0.16

@onready var current_stone: TextureRect = $Current/Row/Stone
@onready var current_face: TextureRect = $Current/Row/Face
@onready var current_name: Label = $Current/Row/Name
@onready var queue: HBoxContainer = $Queue

var slide: Tween = null


func _ready() -> void:
	SignalBus.turn_changed.connect(on_turn)
	SignalBus.seats_changed.connect(on_seats)
	SignalBus.game_started.connect(on_new_game)
	refresh()


func on_turn(_side: String, _move_no: int) -> void:
	refresh()
	animate()


func on_seats(_seats: Array) -> void:
	refresh()


func on_new_game(_mode: String, _ruleset: String, _first: String) -> void:
	refresh()


func stone_for(colour: String) -> Texture2D:
	if colour == "W":
		return STONE_WHITE
	return STONE_BLACK


func face_for(kind: String) -> Texture2D:
	if kind == "ai":
		return ICON_BOT
	if kind == "human":
		return ICON_HUMAN
	return null


func seat_name(index: int) -> String:
	var seat: Dictionary = GameState.seats[index]
	if seat.get("kind", "") == "ai":
		return "AI %d" % (index + 1)
	if GameState.my_seats.has(index):
		return "You"
	return "Player %d" % (index + 1)


func refresh() -> void:
	if GameState.seats.is_empty():
		visible = false
		return
	visible = true
	var count := GameState.seats.size()
	var now := clampi(GameState.turn_seat, 0, count - 1)
	var seat: Dictionary = GameState.seats[now]

	current_stone.texture = stone_for(seat.get("colour", "B"))
	current_face.texture = face_for(seat.get("kind", "empty"))
	current_name.text = seat_name(now)
	build_queue(now, count)


## Everyone after the current seat, wrapping round, so the order shown is the
## order they will actually play.
func build_queue(now: int, count: int) -> void:
	for child in queue.get_children():
		queue.remove_child(child)
		child.queue_free()
	for step in range(1, count):
		queue.add_child(make_chip((now + step) % count))


func make_chip(index: int) -> Control:
	var seat: Dictionary = GameState.seats[index]
	var chip := VBoxContainer.new()
	chip.add_theme_constant_override("separation", 0)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.modulate = Color(1, 1, 1, 0.62)

	var pair := HBoxContainer.new()
	pair.alignment = BoxContainer.ALIGNMENT_CENTER
	pair.add_theme_constant_override("separation", 2)
	pair.add_child(make_icon(stone_for(seat.get("colour", "B")), 22))
	var face := face_for(seat.get("kind", "empty"))
	if face != null:
		pair.add_child(make_icon(face, 22))
	chip.add_child(pair)

	var tag := Label.new()
	tag.text = seat_name(index)
	tag.add_theme_font_size_override("font_size", 11)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(tag)
	return chip


func make_icon(texture: Texture2D, size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture = texture
	return rect


## Slide the whole strip in from the right, which is what makes the rotation
## read as movement rather than a jump cut.
func animate() -> void:
	if slide != null and slide.is_valid():
		slide.kill()
	position.x = SLIDE
	modulate.a = 0.0
	slide = create_tween()
	slide.set_parallel(true)
	slide.tween_property(self, "position:x", 0.0, SLIDE_TIME)
	slide.tween_property(self, "modulate:a", 1.0, SLIDE_TIME)
