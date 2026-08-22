#include "engine.h"

/*
** Announce the pairs the engine just lifted off the board. remove_stone is
** called twice per capture, so the positions arrive already paired up.
*/
static void	report_captures(t_server *server, int mover, t_move_undo *undo)
{
	int	i;
	int	first;
	int	second;

	i = 0;
	while (i + 1 < (int)undo->captured_count)
	{
		first = undo->captured_positions[i];
		second = undo->captured_positions[i + 1];
		proto_broadcast(server, "CAPTURED %s %d %d %d %d", side_name(mover),
			first % BOARD_SIDE, first / BOARD_SIDE,
			second % BOARD_SIDE, second / BOARD_SIDE);
		i += 2;
	}
}

/*
** Ask the engine whether the game is over and publish the verdict. Returns 1
** when the game ended, so callers stop driving it.
*/
int	move_report_end(t_server *server, t_session *session)
{
	char	winner;

	winner = has_won(&session->state);
	if (winner == 'B' || winner == 'W')
	{
		session->finished = 1;
		proto_broadcast(server, "END %c alignment", winner);
		return (1);
	}
	if (is_terminal(&session->state))
	{
		session->finished = 1;
		proto_broadcast(server, "END - draw");
		return (1);
	}
	return (0);
}

/*
** Hand one move to the engine and republish everything it changed.
*/
void	move_apply(t_server *server, t_session *session, int move)
{
	t_move_undo	undo;
	int			mover;

	mover = side_to_move(session);
	proto_broadcast(server, "PLACED %s %d %d %d", side_name(mover),
		move % BOARD_SIDE, move / BOARD_SIDE, (int)session->state.turn + 1);
	undo = play_move_number(&session->state, move);
	report_captures(server, mover, &undo);
	view_board(server, session);
	proto_broadcast(server, "CAPTURES %d %d",
		(int)session->state.captures[SIDE_BLACK],
		(int)session->state.captures[SIDE_WHITE]);
	if (move_report_end(server, session))
		return ;
	view_turn(server, session);
}

/*
** MOVE from a client. Legality is the engine's business, so this only asks it
** what it already knows: is the square on the board and is it empty.
*/
void	cmd_move(t_server *server, t_client *client, t_cmd *cmd)
{
	t_session	*session;
	int			x;
	int			y;

	session = engine_session();
	x = atoi(proto_arg(cmd, 1));
	y = atoi(proto_arg(cmd, 2));
	if (session->active == 0 || session->finished == 1)
		return ((void)proto_emit(client, "REJECT %d %d no_game", x, y));
	if (x < 0 || x >= BOARD_SIDE || y < 0 || y >= BOARD_SIDE)
		return ((void)proto_emit(client, "REJECT %d %d out_of_bounds", x, y));
	if (get_pos(&session->state, y, x) != '0')
		return ((void)proto_emit(client, "REJECT %d %d occupied", x, y));
	if (side_to_move(session) == session->ai_side)
		return ((void)proto_emit(client, "REJECT %d %d not_your_turn", x, y));
	move_apply(server, session, coors_to_move(y, x));
	ai_take_turn(server, session);
}
