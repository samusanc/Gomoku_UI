#include "engine.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/*
** Scaffolding. See the header comment in engine_stub.c before touching this.
*/

/*
** Accept the requested game parameters and clear the goban. Nothing about the
** ruleset is enforced; the string is only echoed back for the UI to display.
*/
void	stub_new(t_server *server, t_client *client, t_cmd *cmd, t_session *s)
{
	(void)client;
	board_init(&s->board);
	s->active = 1;
	s->move_no = 1;
	snprintf(s->mode, sizeof(s->mode), "%s", proto_arg(cmd, 1));
	snprintf(s->ruleset, sizeof(s->ruleset), "%s", proto_arg(cmd, 2));
	s->ai_color = CELL_EMPTY;
	if (strcmp(s->mode, "pva") == 0)
	{
		s->ai_color = CELL_WHITE;
		if (strcmp(proto_arg(cmd, 3), "W") == 0)
			s->ai_color = CELL_BLACK;
	}
	stub_send_snapshot(server, s);
}

/*
** Echo a stone onto the goban and flip the turn so the client can be driven
** end to end. Only the bounds check survives into the real engine, and only
** because it guards the array; occupancy, captures and double-threes are all
** the engine's call, not the server's.
*/
void	stub_move(t_server *server, t_client *client, t_cmd *cmd, t_session *s)
{
	int	x;
	int	y;

	x = atoi(proto_arg(cmd, 1));
	y = atoi(proto_arg(cmd, 2));
	if (s->active == 0)
	{
		proto_emit(client, "REJECT %d %d no_game", x, y);
		return ;
	}
	if (x < 0 || x >= BOARD_SIZE || y < 0 || y >= BOARD_SIZE)
	{
		proto_emit(client, "REJECT %d %d out_of_bounds", x, y);
		return ;
	}
	proto_broadcast(server, "PLACED %s %d %d %d",
		s->board.turn == CELL_BLACK ? "B" : "W", x, y, s->move_no);
	s->board.cells[y][x] = s->board.turn;
	s->board.turn = (s->board.turn == CELL_BLACK) ? CELL_WHITE : CELL_BLACK;
	s->move_no++;
	stub_send_board(server, &s->board);
	proto_broadcast(server, "TURN %s %d",
		s->board.turn == CELL_BLACK ? "B" : "W", s->move_no);
}

/*
** A hint needs a search, so there is nothing honest to answer yet.
*/
void	stub_suggest(t_server *server, t_client *client, t_cmd *cmd,
			t_session *s)
{
	(void)server;
	(void)cmd;
	(void)s;
	proto_emit(client, "ERROR not_implemented no engine attached yet");
}

void	stub_state(t_server *server, t_client *client, t_cmd *cmd, t_session *s)
{
	(void)cmd;
	if (s->active == 0)
	{
		proto_emit(client, "ERROR no_game no game in progress");
		return ;
	}
	stub_send_snapshot(server, s);
}
