# game/ — Godot client (placeholder)

Godot project for the Gomoku GUI. Not initialized yet.

Responsibilities:

- Render the 19x19 goban and the stones.
- Handle player input and move placement.
- Display the **AI think-time timer** (mandatory for project validation).
- Display capture counters for both players.
- Hotseat mode with a move-suggestion button.
- Debug panel showing the AI's reasoning (depth reached, evaluated moves, score).

It holds **no rule logic** — legality, captures, double-threes and win
detection all come from `../server/`.
