#include "engine.h"

/*
** NEW: reset the engine's state and announce the fresh position. The ruleset
** string is only echoed back for the UI; selectable rulesets are a bonus the
** engine does not implement yet.
*/
void	cmd_new(t_server *server, t_client *client, t_cmd *cmd)
{
	t_session	*session;

	(void)client;
	session = engine_session();
	initialize_game_state(&session->state);
	session->active = 1;
	session->finished = 0;
	snprintf(session->mode, sizeof(session->mode), "%s", proto_arg(cmd, 1));
	snprintf(session->ruleset, sizeof(session->ruleset), "%s",
		proto_arg(cmd, 2));
	session->ai_side = SIDE_NONE;
	if (strcmp(session->mode, "pva") == 0)
	{
		session->ai_side = SIDE_WHITE;
		if (strcmp(proto_arg(cmd, 3), "W") == 0)
			session->ai_side = SIDE_BLACK;
	}
	view_snapshot(server, session);
	ai_take_turn(server, session);
}

void	cmd_state(t_server *server, t_client *client)
{
	t_session	*session;

	session = engine_session();
	if (session->active == 0)
	{
		proto_emit(client, "ERROR no_game no game in progress");
		return ;
	}
	view_snapshot(server, session);
}

void	cmd_resign(t_server *server, t_client *client)
{
	t_session	*session;
	int			loser;

	(void)client;
	session = engine_session();
	if (session->active == 0 || session->finished == 1)
	{
		proto_emit(client, "ERROR no_game nothing to resign");
		return ;
	}
	loser = side_to_move(session);
	session->finished = 1;
	if (loser == SIDE_BLACK)
		proto_broadcast(server, "END W resign");
	else
		proto_broadcast(server, "END B resign");
}
