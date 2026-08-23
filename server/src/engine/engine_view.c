#include "room.h"

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
void	view_board(t_server *server, t_room *room)
{
	char	cells[BOARD_CELLS + 1];
	int		i;

	i = 0;
	while (i < BOARD_CELLS)
	{
		cells[i] = '.';
		if (room->session.state.board[i] > 0)
			cells[i] = 'b';
		else if (room->session.state.board[i] < 0)
			cells[i] = 'w';
		i++;
	}
	cells[i] = '\0';
	room_emit(server, room, "BOARD %s", cells);
}

void	view_turn(t_server *server, t_room *room)
{
	room_emit(server, room, "TURN %s %d %d",
		side_name(side_to_move(&room->session)),
		(int)room->session.state.turn + 1, seat_on_turn(room));
}

/*
** Everything a client needs to draw the position from scratch, in the order a
** fresh UI wants it. The seat roster goes first so the player list is filled
** before any move arrives.
*/
void	view_snapshot(t_server *server, t_room *room)
{
	room_view_seats(server, room);
	room_emit(server, room, "GAME %s %s B", room->session.mode,
		room->session.ruleset);
	view_board(server, room);
	room_emit(server, room, "CAPTURES %d %d",
		(int)room->session.state.captures[SIDE_BLACK],
		(int)room->session.state.captures[SIDE_WHITE]);
	view_turn(server, room);
}
