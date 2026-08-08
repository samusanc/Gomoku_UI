extends Node

## Global event bus. Nothing in the client calls another node directly across
## scenes; everything goes through these signals.

## True once the scene that consumes server lines is in the tree and ready.
var SceneLoaded := false

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
