extends VBoxContainer

## Turn, capture counters, and the mandatory AI think-time readout.
##
## The timer counts locally while a THINKING is outstanding so the player sees
## it move, then snaps to the millisecond figure the server reports in THOUGHT.
## That figure is the authoritative one, and the running average is what the
## subject actually grades.

@onready var turn_label: Label = $Turn
@onready var captures_label: Label = $Captures
@onready var timer_label: Label = $Timer
@onready var result_label: Label = $Result

var thinking := false
var elapsed := 0.0
var samples: Array[int] = []


func _ready() -> void:
	SignalBus.turn_changed.connect(on_turn)
	SignalBus.captures_changed.connect(on_captures)
	SignalBus.ai_thinking.connect(on_thinking)
	SignalBus.ai_thought.connect(on_thought)
	SignalBus.game_ended.connect(on_end)
	SignalBus.game_started.connect(on_new_game)
	SignalBus.move_rejected.connect(on_rejected)
	SignalBus.hint_ready.connect(on_hint)
	on_new_game("", "", "B")


func _process(delta: float) -> void:
	if not thinking:
		return
	elapsed += delta
	timer_label.text = "AI  %d ms  thinking" % int(elapsed * 1000.0)


func on_new_game(_mode: String, _ruleset: String, _first: String) -> void:
	samples.clear()
	thinking = false
	result_label.text = ""
	timer_label.text = "AI  --"
	on_turn(GameState.side_to_move, GameState.move_no)
	on_captures(0, 0)


func on_turn(side: String, move_no: int) -> void:
	var who := "Black" if side == "B" else "White"
	var tag := "you" if GameState.is_human_turn() else "AI"
	turn_label.text = "Move %d   %s (%s)" % [move_no, who, tag]


func on_captures(black: int, white: int) -> void:
	captures_label.text = "Captures   B %d/10   W %d/10" % [black, white]


func on_thinking(_side: String) -> void:
	thinking = true
	elapsed = 0.0


func on_thought(_side: String, ms: int, depth: int, _nodes: int,
		score: int) -> void:
	thinking = false
	samples.append(ms)
	var total := 0
	for s in samples:
		total += s
	var average := total / samples.size()
	timer_label.text = "AI  %d ms   avg %d ms   depth %d   score %d" \
		% [ms, average, depth, score]


## With no AI in the game the timer line would just read "--", so the hint
## search time goes there instead. Against the AI its own stats stay put.
func on_hint(_x: int, _y: int, ms: int, depth: int, score: int) -> void:
	if not GameState.has_ai():
		timer_label.text = "Hint  %d ms   depth %d   score %d" % [ms, depth, score]


func on_rejected(x: int, y: int, reason: String) -> void:
	result_label.text = "[%d,%d] refused: %s" % [x, y, reason]


func on_end(winner: String, reason: String) -> void:
	thinking = false
	if winner == "-":
		result_label.text = "Draw (%s)" % reason
		return
	var who := "Black" if winner == "B" else "White"
	result_label.text = "%s wins by %s" % [who, reason]
