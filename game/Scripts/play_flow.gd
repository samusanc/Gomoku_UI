extends Control

## The play menu: pick a mode, then whatever that mode needs, then start.
##
## Screens are siblings and exactly one is visible. Nothing here talks to the
## board; it collects choices, connects, and sends one command. The scene swap
## to the game happens when the server answers with GAME, which main.gd watches
## for, so multiplayer can sit in a lobby after connecting instead of being
## dragged straight into a game.

signal closed()

enum Mode {SOLO, LOCAL, ONLINE}

const MODE_TITLES: Array[String] = ["SOLO", "LOCAL VS", "MULTIPLAYER"]

@onready var cycler: Control = $ModeScreen/Box/VBox/Cycler
@onready var screens := {
	"mode": $ModeScreen,
	"solo": $SoloScreen,
	"local": $LocalScreen,
	"online": $OnlineScreen,
	"create": $CreateScreen,
	"lobby": $LobbyScreen,
}
@onready var code_field: LineEdit = $OnlineScreen/Box/VBox/Code/Field
@onready var seat_pick: Label = $CreateScreen/Box/VBox/Chosen

var mode := Mode.SOLO
var seats_wanted := 2
## What to send once the socket is up.
var pending := ""


func _ready() -> void:
	cycler.setup(MODE_TITLES, 0)
	cycler.mode_changed.connect(on_mode_changed)
	SignalBus.start_game.connect(on_connected)
	SignalBus.stop_load_animation.connect(on_connect_failed)
	show_screen("mode")


func show_screen(name: String) -> void:
	for key in screens:
		screens[key].visible = key == name


func on_mode_changed(index: int) -> void:
	mode = index as Mode


## Next on the mode screen: go where that mode needs to go.
func _on_next_pressed() -> void:
	if mode == Mode.SOLO:
		show_screen("solo")
	elif mode == Mode.LOCAL:
		show_screen("local")
	else:
		show_screen("online")


func _on_back_to_mode_pressed() -> void:
	show_screen("mode")


## Back out of the play menu. If we are sitting in a room, give the seat up
## rather than leaving a ghost in it for a minute.
func _on_leave_pressed() -> void:
	if Network.connected and GameState.room_code != "":
		Network.send_line("LEAVE")
	pending = ""
	closed.emit()


# ------------------------------------------------------------------ starting

## Connect if needed, then send. Everything that starts something funnels here
## so there is one place that knows about the connect-then-send ordering.
func commit(command: String) -> void:
	pending = command
	if Network.connected:
		on_connected()
		return
	SignalBus.new_connection.emit(Settings.host, Settings.port)


func on_connected() -> void:
	if pending == "":
		return
	var line := pending
	pending = ""
	Network.send_line(line)
	if line.begins_with("CREATE") or line.begins_with("JOIN"):
		show_screen("lobby")


func on_connect_failed(_message) -> void:
	pending = ""


func _on_solo_play_pressed() -> void:
	Settings.set_mode(Settings.MODE_AI)
	commit("NEW pva standard %s" % Settings.human_colour)


func _on_local_play_pressed() -> void:
	Settings.set_mode(Settings.MODE_HOTSEAT)
	commit("NEW pvp standard -")


# --------------------------------------------------------------- multiplayer

func _on_join_pressed() -> void:
	var code := code_field.text.strip_edges().to_upper()
	if code.is_empty():
		return
	commit("JOIN %s" % code)


func _on_create_room_pressed() -> void:
	show_screen("create")


func _on_two_pressed() -> void:
	seats_wanted = 2
	seat_pick.text = "2 players"


func _on_four_pressed() -> void:
	seats_wanted = 4
	seat_pick.text = "4 players"


func _on_create_start_pressed() -> void:
	commit("CREATE %d" % seats_wanted)
