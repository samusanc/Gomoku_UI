extends Node

## Global event bus. Nothing in the client calls another node directly across
## scenes; everything goes through these signals.

## One complete protocol line arrived from the server, newline stripped.
signal command(line)

## Free text for the console view (client side notices, not server traffic).
signal new_message(text)

## The menu asked for a connection.
signal new_connection(host, port)

## The socket reached CONNECTED; switch to the game scene.
signal start_game()

## Connection attempt ended badly; stop the spinner and show why.
signal stop_load_animation(message)

## The link dropped. Enables the reconnect button.
signal server_down()

## The reconnect button was pressed.
signal retry_connection()

## Leaving the menu; reset network state before a fresh attempt.
signal hide_menu()

signal enable_crt()
signal disable_crt()

## --- typed game events -------------------------------------------------
## Produced by GameState from the raw `command` stream, so no widget has to
## parse the wire format itself. Still pure presentation: the client decides
## nothing, it only re-shapes what the server said.

signal game_started(mode, ruleset, first)
signal board_changed(cells)
signal turn_changed(side, move_no)
signal stone_placed(side, x, y, move_no)
signal pair_captured(side, x1, y1, x2, y2)
signal captures_changed(black, white)
signal forbidden_changed(side, cells)
signal move_rejected(x, y, reason)
signal ai_thinking(side)
signal ai_thought(side, ms, depth, nodes, score)
signal hint_ready(x, y, ms, depth, score)
signal game_ended(winner, reason)

## The pause menu asked for a fresh game; game_scene owns the parameters.
signal request_new_game()

## Leave the game and go back to the main menu, dropping the connection.
signal leave_game()

## Room identity changed (code, admin seat, started).
signal room_changed(code, admin_seat, started)

## The seat roster changed; carries the whole array.
signal seats_changed(seats)
