# game/ — Godot client

Godot **4.7.1** project. Renders what the server sends and nothing else.

Right now it is a protocol console: connect, receive, print every line, and
reconnect when the link drops. The board rendering goes on top of this later.

## Run

```sh
# with the editor
Godot_v4.7.1-stable_win64.exe --path Gomoku/game

# headless, skipping the menu (useful for checking the link)
Godot_v4.7.1-stable_win64_console.exe --headless --path Gomoku/game -- 127.0.0.1 4242
```

Two positional arguments after `--` are read as host and port and trigger an
immediate connection, bypassing the menu.

## Layout

```
game/
├── project.godot
├── Scenes/
│   ├── Main.tscn            persistent root: SubViewport + CRT post process
│   ├── MainMenuUI.tscn      title, start bar, connect + options panels
│   ├── GameScene.tscn       the board, HUD, actions, protocol log
│   └── PauseMenu.tscn       ESC overlay: resume, rematch, resign, leave
├── Scripts/
│   ├── SignalBus.gd         every cross scene signal
│   ├── Network.gd           TCP link and line framing
│   ├── GameState.gd         parses the protocol once, holds the position
│   ├── main.gd              swaps the viewport content, drives the CRT
│   ├── main_menu.gd         menu routing
│   ├── goban.gd             draws the board, turns clicks into MOVE
│   ├── hud.gd               turn, captures, the mandatory AI timer
│   ├── game_scene.gd        Hint / Rematch / Resign, starts a game
│   ├── pause_menu.gd        ESC overlay
│   └── ...                  title float, spinner, status, raw input
├── Shaders/                 CrtPost, GameBackground, Background, Vignette
└── Assets/                  Fonts (Geist Pixel), Textures
```

## Architecture

**Everything renders into a SubViewport.** `Main.tscn` holds a
`SubViewportContainer` carrying the CRT post process, and the menu or the game
lives inside the viewport. That is why the CRT covers every button, label and
image at once. Consequence: scenes are swapped by replacing the viewport child
in `main.gd` — never with `change_scene_to_file`, which would destroy the root
and the CRT with it.

**One parser.** `GameState` is the only thing that reads the wire format. It
turns raw lines into typed signals (`board_changed`, `turn_changed`,
`ai_thought`, `pair_captured`, ...) and keeps the last known position, so no
widget parses protocol text and a late widget can just ask. Parsing is not
rules: every value it holds was decided by the server.

**The board is one Control.** `goban.gd` draws the grid, stones and markers in
a single `_draw()` rather than with 361 nodes, and converts a click into
`MOVE x y`. It never decides legality — an illegal click just earns a `REJECT`
which the HUD shows.

## How a line travels

```
server socket
  -> Network.read_available()    raw bytes into recv_buffer
  -> Network.drain_lines()       split on newline, partial tail kept
  -> SignalBus.command           one whole line
  -> GameState.on_command()      parsed once
  -> SignalBus.board_changed etc typed events
  -> goban / hud / log           draw only
```

Lines that arrive before the scene is ready are parked in `command_buffer` and
flushed once `SignalBus.SceneLoaded` turns true.

**No game logic lives here.** Legality, captures, free-threes, win detection
and the AI are all the server and engine, per `../PROTOCOL.md`.

## The mandatory timer

`hud.gd` counts locally from `THINKING` so the number visibly moves, then snaps
to the server figure from `THOUGHT` and shows a running average. The average is
what the subject grades, so both are on screen.

## Pausing

ESC opens `PauseMenu.tscn` over the game. It does **not** pause the scene tree:
the server owns the game and keeps running regardless, so freezing our process
would only stall the socket read while the engine carried on thinking, and the
position would then arrive in a burst on resume. The overlay dims the board and
swallows input instead, so no stray click reaches the goban.

`Disconnect` drops the link and returns to the main menu; `Rematch` asks
`game_scene` for a fresh `NEW` so the parameters stay in one place.

## Sending commands by hand

The box under the log in the game scene sends one raw protocol line. Try:

```
STATE
NEW pvp standard -
MOVE 9 9
```

## Verified against the real server

Godot 4.7.1 headless against `gomoku_server` in the dev container:

- connects, sends `HELLO 1`, receives and prints `WELCOME`;
- receives a full broadcast burst (`GAME`, `PLAYER`, `BOARD`, `CAPTURES`,
  `TURN`, `PLACED`) with the 361-character `BOARD` lines intact;
- detects the link dropping and reports `offline`;
- reconnects to the same host and port and resumes.

## Porting notes (4.4 → 4.7)

- `config/features` moved to `4.7`.
- In 4.7 `StreamPeerTCP` gained an abstract base, `StreamPeerSocket`, which now
  owns `poll()`, `get_status()`, `disconnect_from_host()` and the `Status`
  enum. This is **source compatible**: `StreamPeerTCP.STATUS_CONNECTED` still
  resolves through inheritance. The class reference page for `StreamPeerTCP`
  no longer lists those members, which is confusing but harmless.
- `.uid` files next to each script are generated by the editor and are meant to
  be committed; they keep resource references stable across renames.
