#include "engine.h"
#include <string.h>

/*
** THROWAWAY SCAFFOLDING.
**
** This file exists so the Godot client can be built against a live socket
** before the real game logic and AI exist. It validates nothing: no legality,
** no captures, no free-threes, no win detection, no search. Every command that
** needs an actual decision answers ERROR not_implemented.
**
** When the real engine lands, delete src/engine/engine_stub*.c and implement
** the same five entry points. Nothing in src/net/ or src/proto/ changes.
*/

static t_session	g_session;

int	engine_init(t_server *server)
{
	(void)server;
	memset(&g_session, 0, sizeof(g_session));
	board_init(&g_session.board);
	g_session.active = 0;
	g_session.move_no = 1;
	g_session.ai_color = CELL_EMPTY;
	return (0);
}

void	engine_shutdown(t_server *server)
{
	(void)server;
	g_session.active = 0;
}

/*
** A new UI gets its identity plus, if a game is already running, everything it
** needs to draw the current position without asking.
*/
void	engine_client_join(t_server *server, t_client *client)
{
	proto_emit(client, "WELCOME %d %d %d", client->id, PROTO_VERSION,
		BOARD_SIZE);
	if (g_session.active == 1)
		stub_send_snapshot(server, &g_session);
}

void	engine_client_leave(t_server *server, t_client *client)
{
	(void)server;
	(void)client;
}

/*
** Route one parsed command. Unknown verbs are answered, never fatal.
*/
void	engine_handle(t_server *server, t_client *client, t_cmd *cmd)
{
	if (proto_is(cmd, "HELLO"))
		proto_emit(client, "WELCOME %d %d %d", client->id, PROTO_VERSION,
			BOARD_SIZE);
	else if (proto_is(cmd, "PING"))
		proto_emit(client, "PONG");
	else if (proto_is(cmd, "NEW"))
		stub_new(server, client, cmd, &g_session);
	else if (proto_is(cmd, "MOVE"))
		stub_move(server, client, cmd, &g_session);
	else if (proto_is(cmd, "SUGGEST"))
		stub_suggest(server, client, cmd, &g_session);
	else if (proto_is(cmd, "STATE"))
		stub_state(server, client, cmd, &g_session);
	else if (proto_is(cmd, "DEBUG"))
		client->debug = (strcmp(proto_arg(cmd, 1), "on") == 0);
	else if (proto_is(cmd, "UNDO") || proto_is(cmd, "RESIGN"))
		proto_emit(client, "ERROR not_implemented no engine attached yet");
	else if (proto_is(cmd, "BYE"))
		client_remove(server, client->fd);
	else
		proto_emit(client, "ERROR unknown_command %s", proto_arg(cmd, 0));
}
