# server/ — C engine

TCP server that sits between the Godot UI and the game logic + AI.
It owns sockets, line framing and session plumbing. **It owns no rules.**

## Build and run

```sh
make
./gomoku_server 4242
```

Then, in another terminal:

```sh
nc 127.0.0.1 4242
```

See `../PROTOCOL.md` for the wire format.

## Layout

```
server/
├── Makefile
├── includes/
│   ├── gomoku.h        board and cell types
│   ├── net.h           server/client types, socket layer
│   ├── proto.h         command parsing, event emission
│   └── engine.h        THE SEAM: five entry points the logic must implement
└── src/
    ├── main.c          argv, startup, teardown
    ├── board/
    │   └── board.c
    ├── net/
    │   ├── server.c    init, select loop, shutdown
    │   ├── server_io.c accept, read, dispatch
    │   ├── client.c    client table, send, broadcast
    │   └── buffer.c    per-client line framing
    ├── proto/
    │   ├── proto_parse.c
    │   └── proto_emit.c
    └── engine/
        ├── engine_stub.c       <- THROWAWAY
        ├── engine_stub_cmds.c  <- THROWAWAY
        └── engine_stub_view.c  <- THROWAWAY
```

## The engine seam

`includes/engine.h` declares five entry points:

```c
int  engine_init(t_server *server);
void engine_shutdown(t_server *server);
void engine_client_join(t_server *server, t_client *client);
void engine_client_leave(t_server *server, t_client *client);
void engine_handle(t_server *server, t_client *client, t_cmd *cmd);
```

`src/engine/engine_stub*.c` implements them as scaffolding so the Godot client
can be built against a live socket today. The stub validates **nothing**: no
legality, no captures, no free-threes, no win detection, no search. `MOVE`
echoes the stone onto the goban and flips the turn; `SUGGEST`, `UNDO` and
`RESIGN` answer `ERROR not_implemented`.

The only check the stub performs is a bounds check on `x`/`y`, and only because
it guards an array index. Occupancy is deliberately **not** checked — that is a
rule, and rules are the engine's job.

When the real engine lands, delete the three stub files and implement the same
five entry points. Nothing in `src/net/` or `src/proto/` should change.

## Known limitations

- `client_send` blocks if a peer stops reading and its socket buffer fills.
  Fine for one local UI; revisit if spectators are ever added.
- Sessions are process-global: one game per server instance.
- **Half-close is not supported.** `recv() == 0` is treated as a full
  disconnect, so a peer that does `shutdown(SHUT_WR)` and then waits to read is
  dropped. This is standard behaviour, but it bites when testing: `echo CMD |
  nc ...` closes its write side on EOF, so that connection never sees later
  broadcasts. Keep stdin open when you want to watch — use interactive `nc`,
  or `(sleep 10) | nc 127.0.0.1 4242`.
- The stub **broadcasts** its join snapshot, so every connected client sees a
  fresh `GAME`/`BOARD`/`TURN` burst whenever anyone else connects. Harmless
  with a single UI. The real engine should send the join snapshot to the
  joining client only.

## Verified

Under `gomoku-dev` (Debian bookworm, gcc 12, `-Wall -Wextra -Werror -O2`):

- compiles clean, no warnings;
- second `make` is a no-op, and touching one source relinks;
- valgrind: 0 errors, 0 leaks, all heap freed, exit code 0, with a client still
  connected at shutdown;
- survives a 64KB newline-less flood, 8KB single lines, abrupt mid-line
  disconnects, garbage verbs, out-of-range and non-numeric coordinates;
- no descriptor leak across 60 sequential connections;
- line framing handles CRLF, split packets and multiple commands per packet.
