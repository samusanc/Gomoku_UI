#include "room.h"

/*
** Lifecycle. All game state lives in the room table now, so this file only
** starts and stops it.
*/
int	engine_init(t_server *server)
{
	(void)server;
	room_reset_all();
	return (0);
}

void	engine_shutdown(t_server *server)
{
	(void)server;
	room_reset_all();
}

void	engine_client_join(t_server *server, t_client *client)
{
	(void)server;
	proto_emit(client, "WELCOME %d %d %d", client->id, PROTO_VERSION,
		BOARD_SIDE);
}

/*
** A client dropping does not end its game: its seats stay, unheld, and the
** tick hands them to an AI after AI_TAKEOVER_SECONDS.
*/
void	engine_client_leave(t_server *server, t_client *client)
{
	seat_release_client(server, client);
}


/*
** Called about once a second by the accept loop.
*/
void	engine_tick(t_server *server)
{
	room_tick(server);
}
