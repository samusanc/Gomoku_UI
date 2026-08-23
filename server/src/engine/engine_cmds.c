#include "room.h"
#include <string.h>

/*
** NEW starts a local game: one room whose seats all belong to this client,
** except the AI opponent in solo. Multiplayer uses CREATE and JOIN instead.
*/
static void	seat_local(t_room *room, t_client *client, const char *mode,
		const char *human)
{
	int	ai_seat;

	room->seats[0].kind = SEAT_HUMAN;
	room->seats[0].fd = client->fd;
	room->seats[1].kind = SEAT_HUMAN;
	room->seats[1].fd = client->fd;
	room->admin_seat = 0;
	if (strcmp(mode, "pva") != 0)
		return ;
	ai_seat = 1;
	if (strcmp(human, "W") == 0)
		ai_seat = 0;
	room->seats[ai_seat].kind = SEAT_AI;
	room->seats[ai_seat].fd = -1;
}

void	cmd_new(t_server *server, t_client *client, t_cmd *cmd)
{
	t_room	*room;

	room = room_of_client(client);
	if (room != NULL)
		room_release(room);
	room = room_create(2);
	if (room == NULL)
		return ((void)proto_emit(client, "ERROR internal no room free"));
	snprintf(room->session.mode, sizeof(room->session.mode), "%s",
		proto_arg(cmd, 1));
	snprintf(room->session.ruleset, sizeof(room->session.ruleset), "%s",
		proto_arg(cmd, 2));
	seat_local(room, client, proto_arg(cmd, 1), proto_arg(cmd, 3));
	room->session.active = 1;
	room->session.finished = 0;
	room->started = 1;
	view_snapshot(server, room);
	room_view_mine(server, room, client);
	engine_advance(server, room);
}

void	cmd_state(t_server *server, t_client *client)
{
	t_room	*room;

	room = room_of_client(client);
	if (room == NULL || room->session.active == 0)
		return ((void)proto_emit(client, "ERROR no_game no game in progress"));
	view_snapshot(server, room);
	room_view_mine(server, room, client);
}

void	cmd_resign(t_server *server, t_client *client)
{
	t_room	*room;
	int		loser;

	room = room_of_client(client);
	if (room == NULL || room->session.active == 0
		|| room->session.finished == 1)
		return ((void)proto_emit(client, "ERROR no_game nothing to resign"));
	loser = side_to_move(&room->session);
	room->session.finished = 1;
	if (loser == SIDE_BLACK)
		room_emit(server, room, "END W resign");
	else
		room_emit(server, room, "END B resign");
}
