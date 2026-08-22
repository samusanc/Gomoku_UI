# server/ — C server

TCP server between the Godot UI and the AI engine. It owns sockets, line
framing and session plumbing. **It owns no rules and no search.**

## Build and run

```sh
make            # pulls the ai_engine submodule if missing, then builds
./gomoku_server 4242
```

A fresh clone needs the submodule:

```sh
git clone --recurse-submodules <this repo>
# or, in an existing clone:
git submodule update --init --recursive
```

## Layout

```
server/
├── Makefile
├── ai_engine/          <- SUBMODULE: andresmejiaro/gomoku (the engine team's)
├── includes/
│   ├── net.h           server/client types, socket layer
│   ├── proto.h         command parsing, event emission
│   └── engine.h        THE SEAM: five entry points + session type
└── src/
    ├── main.c
    ├── net/            server.c, server_io.c, client.c, buffer.c
    ├── proto/          proto_parse.c, proto_emit.c
    └── engine/         the binding onto ai_engine
        ├── engine_ai.c        lifecycle, the one session
        ├── engine_dispatch.c  verb -> handler
        ├── engine_cmds.c      NEW, STATE, RESIGN
        ├── engine_move.c      MOVE, capture + end reporting
        ├── engine_search.c    time bounded search, THOUGHT, HINT
        └── engine_view.c      BOARD, TURN, snapshot
```

## How the engine is linked

The engine is a plain C library, so it is compiled straight into our binary —
no subprocess, no IPC, nothing between the search and the socket.

Two of its files are deliberately excluded from `AI_SRCS`:

- `gomoku.c` — their `main()`, an AI-vs-AI self-play loop.
- `connect.c` — an unrelated **connect-four** implementation (6x7 board,
  column drops) left over from another exercise. It is not in their Makefile
  either, so it is dead code.

Engine sources compile at `-Wall -Wextra` (no `-Werror`): we want to see their
warnings without our build breaking on code we do not own. Our own sources stay
at `-Wall -Wextra -Werror`.

### What the binding translates

| Protocol | Engine call |
|---|---|
| `NEW` | `initialize_game_state` |
| `MOVE x y` | `get_pos` to check the square, then `play_move_number` |
| capture events | `t_move_undo.captured_positions`, read in pairs |
| `END .. alignment` | `has_won` |
| `END - draw` | `is_terminal` |
| AI move, `SUGGEST` | `negapruning` |
| `BOARD` | `state.board`, sign per cell |
| `CAPTURES` | `state.captures[2]` (stones, not pairs) |
| `TURN` | `state.turn % 2` — black plays the even plies |

Coordinates line up exactly: the engine numbers moves `row * 19 + col`, and the
protocol indexes the board `y * 19 + x`, so `move == y * 19 + x`.

### Time bounded search

`negapruning` takes a fixed depth and cannot be interrupted, and on the current
engine each extra ply costs roughly 6x to 12x the previous one. A blind
depth-10 call would block the server for minutes.

`engine_search` therefore deepens one ply at a time and refuses to start a ply
it predicts will overrun `AI_BUDGET_MS`. The deepest ply that actually finished
is the move played. This is scheduling, not search: it only calls their public
`negapruning`. As the engine gets faster, the reached depth rises on its own.

## Known gaps (engine side, not plumbing)

These are missing in `ai_engine`, so the server cannot report them. Every one
is a subject requirement:

1. **Search depth.** The subject demands **>= 10 plies**; measured on a
   realistic 17-move frontier: depth 6 = 0.475 s, depth 7 = 2.6 s,
   depth 8 = 20.7 s. In play the wrapper currently settles at **depth 5-6**.
   Needs a transposition table, better move ordering, and in-search time
   checks before depth 10 is reachable inside 0.5 s.
2. **Win by capture is not implemented.** `has_won()` only checks alignment;
   `captures[]` is tracked and reported but never ends the game. Their
   `NOTES_eval_todo.md` records this as an open task.
3. **No double-three rule.** Nothing forbids the move, so the server never
   sends `REJECT .. double_three` nor any `FORBIDDEN` list.
4. **No endgame-capture rule.** An alignment of five wins immediately, even
   when the opponent could break it by capturing a pair.
5. **`is_move_valid` is not a legality test.** It gates on
   `available_machine_moves`, a proximity mask used to shrink the search. A
   legal human move far from every stone would be rejected by it, so the
   binding checks `get_pos(...) == '0'` instead.
6. **No node counter**, so `THOUGHT` reports `nodes` as `0`.
7. **`UNDO` is refused**: replaying it needs a stack of `t_move_undo`, which
   nothing keeps yet.

## Verified

Under `gomoku-dev` (Debian bookworm, gcc 12):

- builds clean, second `make` is a no-op, touching one source relinks;
- full games play out over the protocol against the AI;
- **AI move time: avg 78-93 ms, max 239 ms, nothing over 500 ms**;
- captures reported as pairs (`CAPTURED W 8 9 9 9`), `END W alignment` fires;
- `SUGGEST` answers `HINT 8 8 212 6 -5`; `RESIGN` ends the game;
- garbage verbs, out-of-range and post-game moves all refused, never fatal;
- valgrind: 0 errors, 0 leaks, all heap freed, exit 0.

## Other notes

- `client_send` blocks if a peer stops reading and its socket buffer fills.
  Fine for one local UI.
- Sessions are process-global: one game per server instance.
- **Half-close is not supported.** `recv() == 0` is treated as a full
  disconnect, so `echo CMD | nc ...` never sees later broadcasts — keep stdin
  open, e.g. `(sleep 10) | nc 127.0.0.1 4242`.
