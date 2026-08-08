# Gomoku wire protocol — v1

Contract between the C server (`server/`) and the Godot client (`game/`).

## Transport

- TCP over `127.0.0.1:<port>`. The server binds loopback only.
- One message per line, terminated by `\n`. A trailing `\r` is tolerated.
- ASCII, fields separated by single spaces. First field is the verb, uppercase.
- Max line length: 4096 bytes. Longer lines are truncated, not fatal.
- Only `DEBUG` and `ERROR` carry a free-text field, always last, running to the
  end of the line.

## Conventions

- Coordinates are `x y`, both `0..18`. `x` = column left→right, `y` = row
  top→bottom. Board index is `y * 19 + x`.
- Colors are `B` (black, always moves first) and `W` (white). `-` means none.
- Capture counts are **stones**, not pairs. 10 stones = win.

## Division of responsibility

The **client renders and nothing else**. It never decides legality, never
detects captures, never counts alignments, never computes a hint. Every pixel
it draws comes from an event below.

The **server routes and nothing else**. It owns sockets, framing and session
plumbing. Rules and AI live behind the engine seam (`includes/engine.h`) and
are swapped in later without touching `src/net/` or `src/proto/`.

## Client → Server

| Command | Meaning |
|---|---|
| `HELLO <version>` | Handshake. First message after connecting. |
| `NEW <mode> <ruleset> <human_color>` | Start a game. `mode` = `pvp`\|`pva`; `ruleset` = `standard`\|`pro`\|`swap`\|`swap2`; `human_color` = `B`\|`W`\|`-`. |
| `MOVE <x> <y>` | Place a stone for the side to move. |
| `SUGGEST` | Ask the engine for the best move (hotseat hint feature). |
| `UNDO` | Take back the last move; in `pva` both plies. |
| `STATE` | Request a full resync of the current position. |
| `DEBUG <on\|off>` | Subscribe to engine reasoning lines. |
| `RESIGN` | The side to move resigns. |
| `PING` | Keepalive. |
| `BYE` | Clean disconnect. |

## Server → Client

| Event | Meaning |
|---|---|
| `WELCOME <client_id> <version> <board_size>` | Sent on connect and on `HELLO`. |
| `GAME <mode> <ruleset> <first_color>` | A game started. |
| `PLAYER <color> <kind> <name>` | Who holds that color. `kind` = `human`\|`ai`. |
| `BOARD <361 cells>` | Full goban as one field: `.` empty, `b` black, `w` white. |
| `TURN <color> <move_no>` | Whose turn it is now. |
| `PLACED <color> <x> <y> <move_no>` | A stone was placed, and by whom. |
| `CAPTURED <by_color> <x1> <y1> <x2> <y2>` | A pair was removed from the board. |
| `CAPTURES <black> <white>` | Running capture totals, in stones. |
| `FORBIDDEN <color> <n> <x1> <y1> ...` | Cells that color may not play (double-three). |
| `REJECT <x> <y> <reason>` | Move refused. |
| `THINKING <color>` | Engine started searching. Client starts its timer. |
| `THOUGHT <color> <ms> <depth> <nodes> <score>` | Search finished. `ms` is authoritative for the displayed timer. |
| `HINT <x> <y> <ms> <depth> <score>` | Answer to `SUGGEST`. |
| `DEBUG <text...>` | One line of engine reasoning for the debug panel. |
| `END <winner> <reason>` | `winner` = `B`\|`W`\|`-`. |
| `PONG` | Answer to `PING`. |
| `ERROR <code> <text...>` | Protocol-level failure. |

### Reason codes

- `REJECT`: `out_of_bounds`, `occupied`, `not_your_turn`, `double_three`,
  `no_game`, `game_over`.
- `END`: `alignment`, `captures`, `resign`, `draw`.
- `ERROR`: `unknown_command`, `bad_args`, `no_game`, `not_implemented`,
  `internal`.

## Mapping subject requirements onto events

| Subject requirement | Events the client draws |
|---|---|
| Board and stones | `BOARD`, `PLACED` |
| Captures removing a pair | `CAPTURED`, then `BOARD` |
| Win by 10 captures | `CAPTURES`, `END <c> captures` |
| Win by alignment of 5+ | `END <c> alignment` |
| Endgame capture (5-in-a-row not yet a win) | Server simply does not send `END`; the line stays on the board and play continues |
| No double-three | `REJECT x y double_three`, and `FORBIDDEN` to grey cells out in advance |
| Mandatory AI timer | `THINKING` starts it, `THOUGHT <ms>` sets the authoritative value |
| Move suggestion in hotseat | `SUGGEST` → `HINT` |
| AI reasoning debug view | `DEBUG on` → stream of `DEBUG` lines |
| Ruleset selection (bonus) | `NEW <mode> <ruleset> <color>` |

## Example session

```
S: WELCOME 0 1 19
C: HELLO 1
S: WELCOME 0 1 19
C: NEW pva standard B
S: GAME pva standard B
S: PLAYER B human -
S: PLAYER W ai -
S: BOARD ...................................................(361 chars)
S: CAPTURES 0 0
S: TURN B 1
C: MOVE 9 9
S: PLACED B 9 9 1
S: BOARD .........................(with a b at index 180)........
S: TURN W 2
S: THINKING W
S: DEBUG root depth 10 pv 9,8 8,8 10,9
S: THOUGHT W 214 10 184320 35
S: PLACED W 9 8 2
S: BOARD ...
S: TURN B 3
```

## Testing without Godot

```sh
./gomoku_server 4242 &
nc 127.0.0.1 4242
```

Then type commands by hand. The server must never die because of anything
typed here — malformed input answers with `ERROR`, never a crash.
