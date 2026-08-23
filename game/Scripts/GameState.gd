extends Node

## Single reader of the protocol stream.
##
## Turns raw lines into typed signals and keeps the last known position so a
## widget that appears late can just ask. This is parsing, not rules: every
## value here was decided by the server.

const SIZE := 19

var cells := ""
var side_to_move := "B"
var move_no := 1
var captures := {"B": 0, "W": 0}
var mode := ""
var ruleset := ""
var ai_side := ""

## The room roster. seats[i] is {"kind": "human"|"ai"|"empty", "colour": "B"|"W"}
var seats: Array[Dictionary] = []
## Which of those seats this client controls, and which one is on turn.
var my_seats: Array[int] = []
var turn_seat := 0
var room_code := ""
var room_admin := -1
var room_started := false

## Recent raw lines, so a log widget created later can still show them.
const BACKLOG_MAX := 200
var backlog: Array[String] = []
var finished := false
var winner := "-"
var forbidden: Array[Vector2i] = []


func _ready() -> void:
	reset()
	SignalBus.command.connect(on_command)
	SignalBus.hide_menu.connect(reset)


func reset() -> void:
	cells = ".".repeat(SIZE * SIZE)
	side_to_move = "B"
	move_no = 1
	captures = {"B": 0, "W": 0}
	finished = false
	winner = "-"
	forbidden.clear()
	turn_seat = 0


## Cell content as the protocol spells it: '.', 'b' or 'w'.
func cell(x: int, y: int) -> String:
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
		return "."
	return cells[y * SIZE + x]


func is_empty(x: int, y: int) -> bool:
	return cell(x, y) == "."


## True when the seat on turn is one this client controls. With teams there can
## be a human and an AI on the same colour, so the seat is the only thing that
## answers this; the colour cannot.
func is_human_turn() -> bool:
	if finished:
		return false
	if my_seats.is_empty():
		return side_to_move != ai_side
	return my_seats.has(turn_seat)


## Is any seat played by the engine? Drives whether the timer line is in use.
func has_ai() -> bool:
	for seat in seats:
		if seat.get("kind", "") == "ai":
			return true
	return ai_side != ""


func is_forbidden(x: int, y: int) -> bool:
	return forbidden.has(Vector2i(x, y))


func on_command(line: String) -> void:
	backlog.append(line)
	if backlog.size() > BACKLOG_MAX:
		backlog.remove_at(0)
	var p := line.split(" ")
	match p[0]:
		"GAME":
			read_game(p)
		"PLAYER":
			if p.size() >= 3 and p[2] == "ai":
				ai_side = p[1]
		"BOARD":
			if p.size() >= 2:
				cells = p[1]
				SignalBus.board_changed.emit(cells)
		"TURN":
			read_turn(p)
		"ROOM":
			read_room(p)
		"SEAT":
			read_seat(p)
		"YOUSEAT":
			read_my_seats(p)
		"PLACED":
			if p.size() >= 5:
				SignalBus.stone_placed.emit(p[1], int(p[2]), int(p[3]), int(p[4]))
		"CAPTURED":
			if p.size() >= 6:
				SignalBus.pair_captured.emit(p[1], int(p[2]), int(p[3]),
					int(p[4]), int(p[5]))
		"CAPTURES":
			read_captures(p)
		"FORBIDDEN":
			read_forbidden(p)
		"REJECT":
			if p.size() >= 4:
				SignalBus.move_rejected.emit(int(p[1]), int(p[2]), p[3])
		"THINKING":
			if p.size() >= 2:
				SignalBus.ai_thinking.emit(p[1])
		"THOUGHT":
			if p.size() >= 6:
				SignalBus.ai_thought.emit(p[1], int(p[2]), int(p[3]),
					int(p[4]), int(p[5]))
		"HINT":
			if p.size() >= 6:
				SignalBus.hint_ready.emit(int(p[1]), int(p[2]), int(p[3]),
					int(p[4]), int(p[5]))
		"END":
			read_end(p)


func read_game(p: PackedStringArray) -> void:
	if p.size() < 4:
		return
	reset()
	mode = p[1]
	ruleset = p[2]
	ai_side = ""
	SignalBus.game_started.emit(mode, ruleset, p[3])


func read_turn(p: PackedStringArray) -> void:
	if p.size() < 3:
		return
	side_to_move = p[1]
	move_no = int(p[2])
	if p.size() >= 4:
		turn_seat = int(p[3])
	SignalBus.turn_changed.emit(side_to_move, move_no)


func read_room(p: PackedStringArray) -> void:
	if p.size() < 5:
		return
	room_code = p[1]
	room_admin = int(p[3])
	room_started = p[4] == "1"
	seats.clear()
	for i in int(p[2]):
		seats.append({"kind": "empty", "colour": "B" if i % 2 == 0 else "W"})
	SignalBus.room_changed.emit(room_code, room_admin, room_started)


func read_seat(p: PackedStringArray) -> void:
	if p.size() < 4:
		return
	var index := int(p[1])
	while seats.size() <= index:
		seats.append({"kind": "empty", "colour": "B"})
	seats[index] = {"kind": p[2], "colour": p[3]}
	SignalBus.seats_changed.emit(seats)


## YOUSEAT lands after the ROOM and SEAT lines, so anything that cares whether
## a seat is ours has to be told again once it arrives.
func read_my_seats(p: PackedStringArray) -> void:
	my_seats.clear()
	if p.size() < 2:
		return
	for i in range(2, mini(p.size(), 2 + int(p[1]))):
		my_seats.append(int(p[i]))
	SignalBus.seats_changed.emit(seats)


func read_captures(p: PackedStringArray) -> void:
	if p.size() < 3:
		return
	captures["B"] = int(p[1])
	captures["W"] = int(p[2])
	SignalBus.captures_changed.emit(captures["B"], captures["W"])


func read_forbidden(p: PackedStringArray) -> void:
	forbidden.clear()
	if p.size() < 3:
		return
	var count := int(p[2])
	var i := 0
	while i < count and 3 + i * 2 + 1 < p.size():
		forbidden.append(Vector2i(int(p[3 + i * 2]), int(p[4 + i * 2])))
		i += 1
	SignalBus.forbidden_changed.emit(p[1], forbidden)


func read_end(p: PackedStringArray) -> void:
	if p.size() < 3:
		return
	finished = true
	winner = p[1]
	SignalBus.game_ended.emit(winner, p[2])
