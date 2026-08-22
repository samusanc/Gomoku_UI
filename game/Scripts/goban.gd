extends Control

## Draws the 19x19 goban and turns clicks into MOVE lines.
##
## Everything drawn comes from GameState, which got it from the server. The
## board is one Control with a custom _draw rather than 361 nodes, so a full
## repaint stays cheap enough to do on every event.

const SIZE := 19
const MARGIN := 26.0
const STARS := [Vector2i(3, 3), Vector2i(3, 9), Vector2i(3, 15),
	Vector2i(9, 3), Vector2i(9, 9), Vector2i(9, 15),
	Vector2i(15, 3), Vector2i(15, 9), Vector2i(15, 15)]

const COL_BOARD := Color(0.055, 0.075, 0.105, 0.88)
const COL_EDGE := Color(0.55, 0.68, 0.80, 0.35)
const COL_GRID := Color(0.55, 0.68, 0.80, 0.30)
const COL_STAR := Color(0.60, 0.72, 0.84, 0.55)
const COL_BLACK := Color(0.07, 0.08, 0.10)
const COL_WHITE := Color(0.93, 0.95, 0.96)
const COL_RIM := Color(0.0, 0.0, 0.0, 0.55)
const COL_LAST := Color(1.0, 0.85, 0.25, 0.95)
const COL_HINT := Color(0.45, 1.0, 0.55, 0.95)
const COL_BAD := Color(1.0, 0.35, 0.35, 0.75)

var hover := Vector2i(-1, -1)
var last_move := Vector2i(-1, -1)
var hint := Vector2i(-1, -1)
var pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	SignalBus.board_changed.connect(on_board)
	SignalBus.turn_changed.connect(on_turn)
	SignalBus.stone_placed.connect(on_placed)
	SignalBus.hint_ready.connect(on_hint)
	SignalBus.game_started.connect(on_new_game)
	SignalBus.game_ended.connect(on_end)


func _process(delta: float) -> void:
	if hint.x >= 0:
		pulse += delta
		queue_redraw()


func on_board(_cells: String) -> void:
	queue_redraw()


func on_turn(_side: String, _move_no: int) -> void:
	queue_redraw()


func on_placed(_side: String, x: int, y: int, _move_no: int) -> void:
	last_move = Vector2i(x, y)
	hint = Vector2i(-1, -1)
	queue_redraw()


func on_hint(x: int, y: int, _ms: int, _depth: int, _score: int) -> void:
	hint = Vector2i(x, y)
	pulse = 0.0
	queue_redraw()


func on_new_game(_mode: String, _ruleset: String, _first: String) -> void:
	last_move = Vector2i(-1, -1)
	hint = Vector2i(-1, -1)
	queue_redraw()


func on_end(_winner: String, _reason: String) -> void:
	hover = Vector2i(-1, -1)
	queue_redraw()


## Largest centred square that fits, so the board never distorts.
func board_rect() -> Rect2:
	var side := minf(size.x, size.y)
	return Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))


func step() -> float:
	return (board_rect().size.x - 2.0 * MARGIN) / float(SIZE - 1)


func cell_pos(x: int, y: int) -> Vector2:
	var r := board_rect()
	return r.position + Vector2(MARGIN + x * step(), MARGIN + y * step())


## Screen point to intersection, or (-1,-1) when the click is not near one.
func pos_cell(p: Vector2) -> Vector2i:
	var r := board_rect()
	var st := step()
	if st <= 0.0:
		return Vector2i(-1, -1)
	var fx := (p.x - r.position.x - MARGIN) / st
	var fy := (p.y - r.position.y - MARGIN) / st
	var x := int(round(fx))
	var y := int(round(fy))
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
		return Vector2i(-1, -1)
	if absf(fx - float(x)) > 0.45 or absf(fy - float(y)) > 0.45:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var moved := pos_cell(event.position)
		if moved != hover:
			hover = moved
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := pos_cell(event.position)
		if clicked.x >= 0 and GameState.is_human_turn():
			Network.send_line("MOVE %d %d" % [clicked.x, clicked.y])


func draw_stone(centre: Vector2, radius: float, colour: Color) -> void:
	draw_circle(centre, radius, colour)
	draw_arc(centre, radius, 0.0, TAU, 24, COL_RIM, 1.5, true)


func _draw() -> void:
	var r := board_rect()
	draw_rect(r, COL_BOARD, true)
	draw_rect(r, COL_EDGE, false, 1.0)
	for i in SIZE:
		draw_line(cell_pos(0, i), cell_pos(SIZE - 1, i), COL_GRID, 1.0)
		draw_line(cell_pos(i, 0), cell_pos(i, SIZE - 1), COL_GRID, 1.0)
	for s in STARS:
		draw_circle(cell_pos(s.x, s.y), maxf(2.0, step() * 0.09), COL_STAR)
	draw_stones()
	draw_markers()


func draw_stones() -> void:
	var radius := step() * 0.44
	for y in SIZE:
		for x in SIZE:
			var c := GameState.cell(x, y)
			if c == "b":
				draw_stone(cell_pos(x, y), radius, COL_BLACK)
			elif c == "w":
				draw_stone(cell_pos(x, y), radius, COL_WHITE)


func draw_markers() -> void:
	var radius := step() * 0.44
	if last_move.x >= 0:
		draw_arc(cell_pos(last_move.x, last_move.y), radius * 0.45,
			0.0, TAU, 20, COL_LAST, 2.0, true)
	if hint.x >= 0:
		var grow := radius * (1.05 + 0.18 * sin(pulse * 5.0))
		draw_arc(cell_pos(hint.x, hint.y), grow, 0.0, TAU, 28,
			COL_HINT, 2.5, true)
	draw_ghost(radius)


## Preview of the move under the cursor, marked red when the server has told us
## the square is off limits.
func draw_ghost(radius: float) -> void:
	if hover.x < 0 or not GameState.is_human_turn():
		return
	if not GameState.is_empty(hover.x, hover.y):
		return
	if GameState.is_forbidden(hover.x, hover.y):
		draw_arc(cell_pos(hover.x, hover.y), radius, 0.0, TAU, 24,
			COL_BAD, 2.0, true)
		return
	var ghost := COL_BLACK if GameState.side_to_move == "B" else COL_WHITE
	ghost.a = 0.45
	draw_circle(cell_pos(hover.x, hover.y), radius, ghost)
