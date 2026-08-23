extends Control

## Persistent root. Everything the player sees is rendered into a SubViewport
## and then drawn through the CRT post-process, so the filter covers every
## button, label and image at once rather than being attached per node.
##
## Because the content lives inside the viewport, scenes are swapped by
## replacing the viewport's child - never with change_scene_to_file, which
## would destroy this node and the CRT along with it.

const MENU_SCENE := "res://Scenes/MainMenuUI.tscn"
const GAME_SCENE := "res://Scenes/GameScene.tscn"

@onready var screen: SubViewportContainer = $Screen
@onready var view: SubViewport = $Screen/View


func _ready() -> void:
	var mat: ShaderMaterial = screen.material
	# both samplers read the same render, the shader's hints give them
	# their different filtering
	mat.set_shader_parameter("viewportNearest", view.get_texture())
	mat.set_shader_parameter("viewportLinear", view.get_texture())
	set_crt(true)
	SignalBus.game_started.connect(show_game)
	SignalBus.leave_game.connect(leave_game)
	SignalBus.enable_crt.connect(set_crt.bind(true))
	SignalBus.disable_crt.connect(set_crt.bind(false))
	show_scene(MENU_SCENE)


func set_crt(enabled: bool) -> void:
	var mat: ShaderMaterial = screen.material
	mat.set_shader_parameter("crt_enabled", enabled)


## Driven by the GAME event, not by the socket: connecting is not the same as
## having a game, and multiplayer waits in a lobby in between.
func show_game(_mode: String, _ruleset: String, _first: String) -> void:
	if view.get_child_count() > 0 and view.get_child(0).name == "GameScene":
		return
	show_scene(GAME_SCENE)


## Back to the menu, connection dropped, so the next PLAY starts clean.
func leave_game() -> void:
	Network.set_zero()
	show_scene(MENU_SCENE)


## Replace the viewport's content. The old child is detached before the new one
## is added so the two never coexist for a frame.
func show_scene(path: String) -> void:
	for child in view.get_children():
		view.remove_child(child)
		child.queue_free()
	view.add_child(load(path).instantiate())
