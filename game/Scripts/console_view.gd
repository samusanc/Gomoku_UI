extends RichTextLabel

## The whole "game" for now: print every protocol line the server sends.
##
## This node is also what marks the scene as ready to receive, so Network can
## flush the lines it parked while the scene was still loading.

## Bound so a long session cannot grow the label forever.
const MAX_LINES := 400

var line_count := 0


func _ready() -> void:
	bbcode_enabled = true
	scroll_following = true
	text = ""
	SignalBus.command.connect(on_command)
	SignalBus.new_message.connect(on_message)
	SignalBus.SceneLoaded = true
	on_message("[color=gray]-- console ready, waiting for server --[/color]")


## One line straight off the socket. Also echoed to stdout so the same check
## works headless, with no window.
func on_command(line: String) -> void:
	print("<< ", line)
	append_line("[color=#7fd1ff]<<[/color] " + escape_bbcode(line))


## A client side notice, already carrying its own markup.
func on_message(message: String) -> void:
	append_line(message)


func append_line(content: String) -> void:
	if line_count >= MAX_LINES:
		text = ""
		line_count = 0
		append_text("[color=gray]-- trimmed --[/color]\n")
	append_text(content + "\n")
	line_count += 1


## Server data is not markup. Without this a line containing '[' would be
## swallowed by the BBCode parser instead of being displayed.
func escape_bbcode(raw: String) -> String:
	return raw.replace("[", "[lb]")
