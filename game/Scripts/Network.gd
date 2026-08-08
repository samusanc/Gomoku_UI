extends Node

## TCP link to the Gomoku C server.
##
## This node owns framing and nothing else: it turns the byte stream into whole
## protocol lines and republishes them on SignalBus.command. It never inspects
## what a line means. Rules, captures and AI all live in the server, exactly as
## PROTOCOL.md describes, so no game logic ever belongs in this file.

const PROTO_VERSION := 1

## Mirror of the server's BUF_MAX_LEN. A peer that never sends a newline must
## not be able to grow this buffer without bound.
const MAX_BUFFER := 16384

var enable := false
var tcp: StreamPeerTCP = null
var connected := false

## Lines that arrived before the consuming scene was ready.
var command_buffer: Array[String] = []
var flushed := false

## Bytes received so far that do not yet form a complete line.
var recv_buffer := ""

var host_restore := ""
var port_restore := ""
var reported_down := false


func _ready() -> void:
	SignalBus.new_connection.connect(connection)
	SignalBus.retry_connection.connect(retry_connection)
	SignalBus.hide_menu.connect(set_zero)

	# Skip the menu when a host and port are passed after `--`, so the client
	# can be driven headlessly:  godot --headless --path game -- 127.0.0.1 4242
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		autoconnect.call_deferred(args[0], args[1])


func autoconnect(host: String, port: String) -> void:
	print("[net] autoconnect from command line: ", host, ":", port)
	SignalBus.hide_menu.emit()
	SignalBus.new_connection.emit(host, port)


## Drop every trace of the previous session so a reconnect starts clean.
func set_zero() -> void:
	flushed = false
	command_buffer.clear()
	recv_buffer = ""
	connected = false
	enable = false
	if tcp != null:
		tcp.disconnect_from_host()
	tcp = null
	SignalBus.SceneLoaded = false
	reported_down = false


func retry_connection() -> void:
	set_zero()
	SignalBus.new_connection.emit(host_restore, port_restore)


func connection(host: String, port: String) -> void:
	host_restore = host
	port_restore = port
	recv_buffer = ""
	tcp = StreamPeerTCP.new()

	var err: Error = tcp.connect_to_host(host, int(port))
	if err != OK:
		error("could not reach %s:%s (error %d)" % [host, port, err])
		return
	print("[net] connecting to ", host, ":", port)
	enable = true


func error(message: String) -> void:
	print("[net] ", message)
	SignalBus.stop_load_animation.emit(message)
	set_zero()


func _process(_delta: float) -> void:
	if not enable:
		return
	if SignalBus.SceneLoaded and not flushed:
		for line in command_buffer:
			SignalBus.command.emit(line)
		command_buffer.clear()
		flushed = true
	listen()


func listen() -> void:
	# Required: StreamPeerTCP only advances its state machine when polled.
	tcp.poll()

	match tcp.get_status():
		StreamPeerTCP.STATUS_CONNECTING:
			pass

		StreamPeerTCP.STATUS_CONNECTED:
			if not connected:
				connected = true
				print("[net] connected")
				send_line("HELLO %d" % PROTO_VERSION)
				SignalBus.start_game.emit()
			read_available()

		StreamPeerTCP.STATUS_ERROR:
			error("server connection failed")

		StreamPeerTCP.STATUS_NONE:
			if not reported_down:
				reported_down = true
				print("[net] link down")
				SignalBus.server_down.emit()


func read_available() -> void:
	var available := tcp.get_available_bytes()
	if available <= 0:
		return

	var result: Array = tcp.get_data(available)
	if result[0] != OK:
		error("reading data failed (error %d)" % result[0])
		return

	var chunk: PackedByteArray = result[1]
	recv_buffer += chunk.get_string_from_utf8()
	if recv_buffer.length() > MAX_BUFFER:
		error("server sent an over long line")
		return
	drain_lines()


## Split the buffer on newlines and publish only whole lines, keeping any
## partial tail for the next poll. A line split across two TCP reads is
## reassembled here rather than reaching the consumer broken in half.
func drain_lines() -> void:
	var newline := recv_buffer.find("\n")
	while newline != -1:
		var line := recv_buffer.substr(0, newline).strip_edges()
		recv_buffer = recv_buffer.substr(newline + 1)
		if not line.is_empty():
			deliver(line)
		newline = recv_buffer.find("\n")


## Before the consuming scene exists, lines are parked instead of dropped.
func deliver(line: String) -> void:
	if SignalBus.SceneLoaded and flushed:
		SignalBus.command.emit(line)
	else:
		command_buffer.append(line)


## Send one command. The newline is added here so callers never think about
## framing. Used by HELLO today, by MOVE and SUGGEST once the board exists.
func send_line(line: String) -> void:
	if tcp == null or tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("[net] dropped outgoing line, not connected: ", line)
		return
	tcp.put_data((line + "\n").to_utf8_buffer())
