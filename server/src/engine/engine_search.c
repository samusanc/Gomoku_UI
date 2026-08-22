#include "engine.h"

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

/*
** Let the AI play if it is on turn. THOUGHT carries the authoritative think
** time the UI must display; nodes is reported as 0 because the engine does
** not expose a node counter yet.
*/
void	ai_take_turn(t_server *server, t_session *session)
{
	t_search_result	result;
	int				side;

	if (session->active == 0 || session->finished == 1)
		return ;
	side = side_to_move(session);
	if (side != session->ai_side)
		return ;
	proto_broadcast(server, "THINKING %s", side_name(side));
	engine_search(session, &result);
	proto_broadcast(server, "THOUGHT %s %d %d 0 %d", side_name(side),
		result.ms, result.depth, result.score);
	if (result.move < 0)
	{
		proto_broadcast(server, "ERROR internal engine returned no move");
		return ;
	}
	move_apply(server, session, result.move);
}

/*
** SUGGEST: same search, but the move is only reported, never played.
*/
void	cmd_suggest(t_server *server, t_client *client)
{
	t_session		*session;
	t_search_result	result;

	(void)server;
	session = engine_session();
	if (session->active == 0 || session->finished == 1)
	{
		proto_emit(client, "ERROR no_game nothing to suggest");
		return ;
	}
	engine_search(session, &result);
	if (result.move < 0)
	{
		proto_emit(client, "ERROR internal engine returned no move");
		return ;
	}
	proto_emit(client, "HINT %d %d %d %d %d",
		result.move % BOARD_SIDE, result.move / BOARD_SIDE,
		result.ms, result.depth, result.score);
}
