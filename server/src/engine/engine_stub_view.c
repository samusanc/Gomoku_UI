#include "engine.h"

/*
** Scaffolding. See the header comment in engine_stub.c before touching this.
*/

/*
** Serialize the goban as one field of BOARD_SIZE * BOARD_SIZE characters,
** index y * BOARD_SIZE + x. This is the only thing the client draws stones
** from; PLACED and CAPTURED are for animation, BOARD is the truth.
*/
void	stub_send_board(t_server *server, t_board *board)
{
	char	cells[BOARD_SIZE * BOARD_SIZE + 1];
	t_cell	value;
	int		i;

	i = 0;
	while (i < BOARD_SIZE * BOARD_SIZE)
	{
		value = board->cells[i / BOARD_SIZE][i % BOARD_SIZE];
		cells[i] = '.';
		if (value == CELL_BLACK)
			cells[i] = 'b';
		else if (value == CELL_WHITE)
			cells[i] = 'w';
		i++;
	}
	cells[i] = '\0';
	proto_broadcast(server, "BOARD %s", cells);
}

/*
** Everything a client needs to draw the position from scratch, in the order a
** fresh UI wants it. Sent on join, on NEW and on STATE.
*/
void	stub_send_snapshot(t_server *server, t_session *session)
{
	proto_broadcast(server, "GAME %s %s B", session->mode, session->ruleset);
	proto_broadcast(server, "PLAYER B %s -",
		session->ai_color == CELL_BLACK ? "ai" : "human");
	proto_broadcast(server, "PLAYER W %s -",
		session->ai_color == CELL_WHITE ? "ai" : "human");
	stub_send_board(server, &session->board);
	proto_broadcast(server, "CAPTURES %d %d", session->board.captures_black,
		session->board.captures_white);
	proto_broadcast(server, "TURN %s %d",
		session->board.turn == CELL_BLACK ? "B" : "W", session->move_no);
}
