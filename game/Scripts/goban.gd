extends Control

## Draws the 19x19 goban and turns clicks into MOVE lines.
##
## Everything drawn comes from GameState, which got it from the server. The
## board is one Control with a custom _draw rather than 361 nodes, so a full
## repaint stays cheap enough to do on every event.

const SIZE := 19
const BOARD_TEX := preload("res://Assets/Textures/gomokuBoard.png")

## Where the painted grid sits inside the board artwork, as a fraction of the
## image. Measured off gomokuBoard.png by least-squares fitting the 18 clean
## interior lines (the outermost ones bleed into the frame shadow): worst
## residual 2.4 px on a 1024 px image, cells square to within 0.4%. Positions
## are fractions rather than pixels so alignment holds at any display size.
const GRID_LEFT := 0.038449
const GRID_RIGHT := 0.960475
const GRID_TOP := 0.045252
const GRID_BOTTOM := 0.937536

const COL_SHADOW := Color(0.0, 0.0, 0.0, 0.45)
const SHADOW_DROP := Vector2(12.0, 16.0)

const COL_BLACK := Color(0.07, 0.08, 0.10)
const COL_WHITE := Color(0.93, 0.95, 0.96)
const COL_RIM := Color(0.0, 0.0, 0.0, 0.55)
const COL_LAST := Color(1.0, 0.85, 0.25, 0.95)
const COL_HINT := Color(0.45, 1.0, 0.55, 0.95)
const COL_BAD := Color(1.0, 0.35, 0.35, 0.75)

## Sit the board against the side menu instead of centring it in the slack.
@export var hug_right := true

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


## The artwork, fitted into the available space without distorting it.
##
## Pushed to the right rather than centred: the board is followed by the side
## menu, and a centred square leaves a gap between the two that reads as the
## menu being adrift on the far edge.
func board_rect() -> Rect2:
	var tex_size := BOARD_TEX.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)
	var aspect := tex_size.x / tex_size.y
	var w := size.x
	var h := w / aspect
	if h > size.y:
		h = size.y
		w = h * aspect
	var top := (size.y - h) * 0.5
	if hug_right:
		return Rect2(Vector2(size.x - w, top), Vector2(w, h))
	return Rect2(Vector2((size.x - w) * 0.5, top), Vector2(w, h))


## Cell pitch in pixels, the smaller axis so stones never overlap a line.
func step() -> float:
	var r := board_rect()
	var sx := r.size.x * (GRID_RIGHT - GRID_LEFT) / float(SIZE - 1)
	var sy := r.size.y * (GRID_BOTTOM - GRID_TOP) / float(SIZE - 1)
	return minf(sx, sy)


func cell_pos(x: int, y: int) -> Vector2:
	var r := board_rect()
	var fx := GRID_LEFT + (GRID_RIGHT - GRID_LEFT) * float(x) / float(SIZE - 1)
	var fy := GRID_TOP + (GRID_BOTTOM - GRID_TOP) * float(y) / float(SIZE - 1)
	return r.position + Vector2(r.size.x * fx, r.size.y * fy)


## Screen point to intersection, or (-1,-1) when the click is not near one.
func pos_cell(p: Vector2) -> Vector2i:
	var r := board_rect()
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return Vector2i(-1, -1)
	var fx := ((p.x - r.position.x) / r.size.x - GRID_LEFT) \
		/ (GRID_RIGHT - GRID_LEFT) * float(SIZE - 1)
	var fy := ((p.y - r.position.y) / r.size.y - GRID_TOP) \
		/ (GRID_BOTTOM - GRID_TOP) * float(SIZE - 1)
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
	# a plain offset block, the same idea as the button shadows
	draw_rect(Rect2(r.position + SHADOW_DROP, r.size), COL_SHADOW, true)
	draw_texture_rect(BOARD_TEX, r, false)
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
