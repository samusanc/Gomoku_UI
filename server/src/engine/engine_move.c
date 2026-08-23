#include "room.h"

/*
** Announce the pairs the engine just lifted off the board. remove_stone is
** called twice per capture, so the positions arrive already paired up.
*/
static void	report_captures(t_server *server, t_room *room, int mover,
		t_move_undo *undo)
{
	int	i;
	int	first;
	int	second;

	i = 0;
	while (i + 1 < (int)undo->captured_count)
	{
		first = undo->captured_positions[i];
		second = undo->captured_positions[i + 1];
		room_emit(server, room, "CAPTURED %s %d %d %d %d", side_name(mover),
			first % BOARD_SIDE, first / BOARD_SIDE,
			second % BOARD_SIDE, second / BOARD_SIDE);
		i += 2;
	}
}

/*
** Ask the engine whether the game is over and publish the verdict. Returns 1
** when the game ended, so callers stop driving it.
*/
int	move_report_end(t_server *server, t_room *room)
{
	char	winner;

	winner = has_won(&room->session.state);
	if (winner == 'B' || winner == 'W')
	{
		room->session.finished = 1;
		room_emit(server, room, "END %c alignment", winner);
		return (1);
	}
	if (is_terminal(&room->session.state))
	{
		room->session.finished = 1;
		room_emit(server, room, "END - draw");
		return (1);
	}
	return (0);
}

/*
** Hand one move to the engine and republish everything it changed.
*/
void	move_apply(t_server *server, t_room *room, int move)
{
	t_move_undo	undo;
	int			mover;

	mover = side_to_move(&room->session);
	room_emit(server, room, "PLACED %s %d %d %d", side_name(mover),
		move % BOARD_SIDE, move / BOARD_SIDE,
		(int)room->session.state.turn + 1);
	undo = play_move_number(&room->session.state, move);
	report_captures(server, room, mover, &undo);
	view_board(server, room);
	room_emit(server, room, "CAPTURES %d %d",
		(int)room->session.state.captures[SIDE_BLACK],
		(int)room->session.state.captures[SIDE_WHITE]);
	if (move_report_end(server, room))
		return ;
	view_turn(server, room);
}

/*
** MOVE from a client. Legality is the engine's business, so this only asks it
** what it already knows, plus the one thing the engine cannot know: whether
** this client owns the seat that is on turn.
*/
void	cmd_move(t_server *server, t_client *client, t_cmd *cmd)
{
	t_room	*room;
	int		x;
	int		y;

	x = atoi(proto_arg(cmd, 1));
	y = atoi(proto_arg(cmd, 2));
	room = room_of_client(client);
	if (room == NULL || room->session.active == 0 || room->session.finished == 1)
		return ((void)proto_emit(client, "REJECT %d %d no_game", x, y));
	if (x < 0 || x >= BOARD_SIDE || y < 0 || y >= BOARD_SIDE)
		return ((void)proto_emit(client, "REJECT %d %d out_of_bounds", x, y));
	if (get_pos(&room->session.state, y, x) != '0')
		return ((void)proto_emit(client, "REJECT %d %d occupied", x, y));
	if (seat_owned_by(room, seat_on_turn(room), client) == 0)
		return ((void)proto_emit(client, "REJECT %d %d not_your_turn", x, y));
	move_apply(server, room, coors_to_move(y, x));
	engine_advance(server, room);
}
