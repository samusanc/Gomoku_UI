#include "engine.h"

/*
** The one live session. The engine keeps all game state in a t_game_state, so
** this file owns exactly one of those and nothing else.
*/
static t_session	g_session;

t_session	*engine_session(void)
{
	return (&g_session);
}

int	engine_init(t_server *server)
{
	(void)server;
	memset(&g_session, 0, sizeof(g_session));
	initialize_game_state(&g_session.state);
	g_session.active = 0;
	g_session.finished = 0;
	g_session.ai_side = SIDE_NONE;
	return (0);
}

void	engine_shutdown(t_server *server)
{
	(void)server;
	g_session.active = 0;
}

void	engine_client_join(t_server *server, t_client *client)
{
	proto_emit(client, "WELCOME %d %d %d", client->id, PROTO_VERSION,
		BOARD_SIDE);
	if (g_session.active == 1)
		view_snapshot(server, &g_session);
}

void	engine_client_leave(t_server *server, t_client *client)
{
	(void)server;
	(void)client;
}
