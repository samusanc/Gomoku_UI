#include "engine.h"

/*
** Route one parsed command to the engine. Anything the engine cannot answer
** yet is refused explicitly, never silently ignored.
*/
void	engine_handle(t_server *server, t_client *client, t_cmd *cmd)
{
	if (proto_is(cmd, "HELLO"))
		proto_emit(client, "WELCOME %d %d %d", client->id, PROTO_VERSION,
			BOARD_SIDE);
	else if (proto_is(cmd, "PING"))
		proto_emit(client, "PONG");
	else if (proto_is(cmd, "NEW"))
		cmd_new(server, client, cmd);
	else if (proto_is(cmd, "MOVE"))
		cmd_move(server, client, cmd);
	else if (proto_is(cmd, "SUGGEST"))
		cmd_suggest(server, client);
	else if (proto_is(cmd, "STATE"))
		cmd_state(server, client);
	else if (proto_is(cmd, "RESIGN"))
		cmd_resign(server, client);
	else if (proto_is(cmd, "DEBUG"))
		client->debug = (strcmp(proto_arg(cmd, 1), "on") == 0);
	else if (proto_is(cmd, "UNDO"))
		proto_emit(client, "ERROR not_implemented undo needs a move history");
	else if (proto_is(cmd, "BYE"))
		client_remove(server, client->fd);
	else
		proto_emit(client, "ERROR unknown_command %s", proto_arg(cmd, 0));
}
