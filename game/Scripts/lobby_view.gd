extends Control

## The room lobby: who is in which seat, and the admin controls.
##
## The roster is rebuilt from GameState every time the server sends one, rather
## than tracked incrementally, so it cannot drift out of step with the server.

const ICON_HUMAN := preload("res://Assets/Textures/icon_human.png")
const ICON_BOT := preload("res://Assets/Textures/icon_bot.png")
const STONE_BLACK := preload("res://Assets/Textures/stone_black.png")
const STONE_WHITE := preload("res://Assets/Textures/stone_white.png")

@onready var code_label: Label = $Panel/Box/VBox/Head/Code
@onready var copy_button: Button = $Panel/Box/VBox/Head/Copy
@onready var rows: VBoxContainer = $Panel/Box/VBox/Players
@onready var add_ai_button: Button = $Panel/Box/VBox/Admin/AddAi
@onready var start_button: Button = $Panel/Box/VBox/Admin/Start
@onready var hint: Label = $Panel/Box/VBox/Hint


func _ready() -> void:
	SignalBus.seats_changed.connect(on_seats)
	SignalBus.room_changed.connect(on_room)
	refresh()


func on_room(_code: String, _admin: int, _started: bool) -> void:
	refresh()


func on_seats(_seats: Array) -> void:
	refresh()


func is_admin() -> bool:
	return GameState.my_seats.has(GameState.room_admin)


func refresh() -> void:
	code_label.text = GameState.room_code
	copy_button.visible = is_admin() and GameState.room_code != ""
	add_ai_button.visible = is_admin()
	start_button.visible = is_admin()
	if is_admin():
		hint.text = "Share the code. Empty seats become AI when you start."
	else:
		hint.text = "Waiting for the room admin to start."
	build_rows()


## One row per seat: stone, icon, label.
func build_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var index := 0
	for seat in GameState.seats:
		rows.add_child(make_row(index, seat))
		index += 1


func make_row(index: int, seat: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var stone := TextureRect.new()
	stone.custom_minimum_size = Vector2(34, 34)
	stone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stone.texture = STONE_BLACK if seat.get("colour", "B") == "B" \
		else STONE_WHITE
	row.add_child(stone)

	var kind: String = seat.get("kind", "empty")
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(34, 34)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if kind == "human":
		face.texture = ICON_HUMAN
	elif kind == "ai":
		face.texture = ICON_BOT
	row.add_child(face)

	var text := Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.text = row_label(index, kind)
	row.add_child(text)
	return row


func row_label(index: int, kind: String) -> String:
	var mine := " (you)" if GameState.my_seats.has(index) else ""
	var admin := " admin" if index == GameState.room_admin else ""
	if kind == "human":
		return "Player %d%s%s" % [index + 1, mine, admin]
	if kind == "ai":
		return "AI%s" % admin
	return "waiting..."


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(GameState.room_code)
	copy_button.text = "Copied"


func _on_add_ai_pressed() -> void:
	Network.send_line("ADDAI")


func _on_start_pressed() -> void:
	Network.send_line("BEGIN")
