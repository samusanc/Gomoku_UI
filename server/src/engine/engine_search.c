#include "room.h"

static double	now_ms(void)
{
	struct timeval	t;

	gettimeofday(&t, NULL);
	return (t.tv_sec * 1000.0 + t.tv_usec / 1000.0);
}

/*
** Iterative deepening around the engine's fixed depth search.
**
** negapruning cannot be interrupted, so the only safe way to respect the
** subject's half second is to finish a ply, then refuse to start the next one
** when it is predicted to overrun. The deepest ply that actually completed is
** the one we play, so the server can never block on a runaway search.
*/
void	engine_search(t_session *session, t_search_result *result)
{
	double	start;
	double	spent;
	int		depth;
	int		move;
	int		score;

	start = now_ms();
	result->move = -1;
	result->depth = 0;
	result->score = 0;
	depth = 1;
	while (depth <= AI_MAX_DEPTH)
	{
		move = -1;
		score = negapruning(depth, &session->state, -SCORE_INF, SCORE_INF,
				1, &move);
		spent = now_ms() - start;
		if (move >= 0)
		{
			result->move = move;
			result->depth = depth;
			result->score = score;
		}
		if (spent * AI_GROWTH > AI_BUDGET_MS)
			break ;
		depth++;
	}
	result->ms = (int)(now_ms() - start);
}

static void	ai_play_once(t_server *server, t_room *room)
{
	t_search_result	result;
	int				side;

	side = side_to_move(&room->session);
	room_emit(server, room, "THINKING %s", side_name(side));
	engine_search(&room->session, &result);
	room_emit(server, room, "THOUGHT %s %d %d 0 %d", side_name(side),
		result.ms, result.depth, result.score);
	if (result.move < 0)
	{
		room_emit(server, room, "ERROR internal engine returned no move");
		room->session.finished = 1;
		return ;
	}
	move_apply(server, room, result.move);
}

/*
** Let every AI seat that is on turn play, one after another. With four seats
** the rotation can hand two AI seats the move back to back, so this loops
** rather than firing once.
*/
void	engine_advance(t_server *server, t_room *room)
{
	int	guard;

	if (room == NULL || room->session.active == 0)
		return ;
	guard = 0;
	while (room->session.finished == 0 && guard < MAX_SEATS
		&& room->seats[seat_on_turn(room)].kind == SEAT_AI)
	{
		ai_play_once(server, room);
		guard++;
	}
}

/*
** SUGGEST: same search, but the move is only reported, never played.
*/
void	cmd_suggest(t_server *server, t_client *client)
{
	t_room			*room;
	t_search_result	result;

	(void)server;
	room = room_of_client(client);
	if (room == NULL || room->session.active == 0
		|| room->session.finished == 1)
		return ((void)proto_emit(client, "ERROR no_game nothing to suggest"));
	engine_search(&room->session, &result);
	if (result.move < 0)
		return ((void)proto_emit(client,
				"ERROR internal engine returned no move"));
	proto_emit(client, "HINT %d %d %d %d %d",
		result.move % BOARD_SIDE, result.move / BOARD_SIDE,
		result.ms, result.depth, result.score);
}
