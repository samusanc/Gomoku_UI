#include "room.h"
#include <string.h>

/*
** CREATE <seats>: open a room, take the first seat, become its admin. The
** game does not start until BEGIN.
*/
void	cmd_create(t_server *server, t_client *client, t_cmd *cmd)
{
	t_room	*room;
	int		seats;

	room = room_of_client(client);
	if (room != NULL)
		room_release(room);
	seats = atoi(proto_arg(cmd, 1));
	room = room_create(seats);
	if (room == NULL)
		return ((void)proto_emit(client,
				"ERROR bad_args seats must be 2 or 4"));
	snprintf(room->session.mode, sizeof(room->session.mode), "%s", "online");
	snprintf(room->session.ruleset, sizeof(room->session.ruleset), "%s",
		"standard");
	if (seat_take(room, client) < 0)
		return ((void)proto_emit(client, "ERROR internal room full"));
	room_view_seats(server, room);
}

/*
** JOIN <code>: take the lowest free seat of an existing room.
*/
void	cmd_join(t_server *server, t_client *client, t_cmd *cmd)
{
	t_room	*room;

	room = room_by_code(proto_arg(cmd, 1));
	if (room == NULL)
		return ((void)proto_emit(client, "ERROR no_room unknown code"));
	if (room->started == 1)
		return ((void)proto_emit(client, "ERROR no_room game already started"));
	if (room_of_client(client) != NULL)
		return ((void)proto_emit(client, "ERROR bad_args already in a room"));
	if (seat_take(room, client) < 0)
		return ((void)proto_emit(client, "ERROR no_room room is full"));
	room_view_seats(server, room);
}

/*
** ADDAI: admin fills the next empty seat with an AI, so a half full room can
** still start.
*/
void	cmd_addai(t_server *server, t_client *client)
{
	t_room	*room;

	room = room_of_client(client);
	if (room == NULL)
		return ((void)proto_emit(client, "ERROR no_room not in a room"));
	if (seat_owned_by(room, room->admin_seat, client) == 0)
		return ((void)proto_emit(client, "ERROR bad_args admin only"));
	if (seat_add_ai(room) < 0)
		return ((void)proto_emit(client, "ERROR no_room no empty seat"));
	room_view_seats(server, room);
}

/*
** BEGIN: admin starts the game. Any seat still empty becomes an AI so the
** rotation always has somebody to play it.
*/
void	cmd_begin(t_server *server, t_client *client)
{
	t_room	*room;

	room = room_of_client(client);
	if (room == NULL)
		return ((void)proto_emit(client, "ERROR no_room not in a room"));
	if (seat_owned_by(room, room->admin_seat, client) == 0)
		return ((void)proto_emit(client, "ERROR bad_args admin only"));
	if (room->started == 1)
		return ((void)proto_emit(client, "ERROR bad_args already started"));
	while (seat_add_ai(room) >= 0)
		;
	initialize_game_state(&room->session.state);
	room->session.active = 1;
	room->session.finished = 0;
	room->started = 1;
	view_snapshot(server, room);
	engine_advance(server, room);
}

void	cmd_leave(t_server *server, t_client *client)
{
	seat_release_client(server, client);
	proto_emit(client, "LEFT");
}
