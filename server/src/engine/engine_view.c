#include "engine.h"

/*
** Protocol name of a side. The engine has no notion of these letters; it only
** knows positive and negative cells.
*/
const char	*side_name(int side)
{
	if (side == SIDE_BLACK)
		return ("B");
	if (side == SIDE_WHITE)
		return ("W");
	return ("-");
}

/*
** Whose turn it is, derived from the engine's own turn counter: black plays
** the even plies.
*/
int	side_to_move(t_session *session)
{
	return ((int)(session->state.turn % 2));
}

/*
** Serialize the goban as one field of BOARD_CELLS characters, index
** y * 19 + x, which is exactly the engine's own move numbering.
*/
void	view_board(t_server *server, t_session *session)
{
	char	cells[BOARD_CELLS + 1];
	int		i;

	i = 0;
	while (i < BOARD_CELLS)
	{
		cells[i] = '.';
		if (session->state.board[i] > 0)
			cells[i] = 'b';
		else if (session->state.board[i] < 0)
			cells[i] = 'w';
		i++;
	}
	cells[i] = '\0';
	proto_broadcast(server, "BOARD %s", cells);
}

void	view_turn(t_server *server, t_session *session)
{
	proto_broadcast(server, "TURN %s %d", side_name(side_to_move(session)),
		(int)session->state.turn + 1);
}

/*
** Everything a client needs to draw the position from scratch, in the order a
** fresh UI wants it.
*/
void	view_snapshot(t_server *server, t_session *session)
{
	proto_broadcast(server, "GAME %s %s B", session->mode, session->ruleset);
	proto_broadcast(server, "PLAYER B %s -",
		session->ai_side == SIDE_BLACK ? "ai" : "human");
	proto_broadcast(server, "PLAYER W %s -",
		session->ai_side == SIDE_WHITE ? "ai" : "human");
	view_board(server, session);
	proto_broadcast(server, "CAPTURES %d %d",
		(int)session->state.captures[SIDE_BLACK],
		(int)session->state.captures[SIDE_WHITE]);
	view_turn(server, session);
}
