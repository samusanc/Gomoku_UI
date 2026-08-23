#include "room.h"
#include <string.h>

/*
** Put a client in the lowest free seat. Returns the seat index, or -1 when the
** room is full.
*/
int	seat_take(t_room *room, t_client *client)
{
	int	s;

	s = 0;
	while (s < room->seat_count)
	{
		if (room->seats[s].kind == SEAT_EMPTY)
		{
			room->seats[s].kind = SEAT_HUMAN;
			room->seats[s].fd = client->fd;
			room->seats[s].vacated_at = 0;
			if (room->admin_seat < 0)
				room->admin_seat = s;
			return (s);
		}
		s++;
	}
	return (-1);
}

/*
** The client is gone. Its seats stay human but unheld, and start a clock: the
** tick converts them to AI once it runs out. An unstarted room with nobody
** left is thrown away instead.
*/
void	seat_release_client(t_server *server, t_client *client)
{
	t_room	*room;
	int		s;
	int		humans;

	room = room_of_client(client);
	if (room == NULL)
		return ;
	s = 0;
	humans = 0;
	while (s < room->seat_count)
	{
		if (room->seats[s].kind == SEAT_HUMAN && room->seats[s].fd == client->fd)
		{
			room->seats[s].fd = -1;
			room->seats[s].vacated_at = room_now();
		}
		else if (room->seats[s].kind == SEAT_HUMAN && room->seats[s].fd >= 0)
			humans++;
		s++;
	}
	if (humans == 0)
		return (room_release(room));
	room_view_seats(server, room);
}

int	seat_add_ai(t_room *room)
{
	int	s;

	s = 0;
	while (s < room->seat_count)
	{
		if (room->seats[s].kind == SEAT_EMPTY)
		{
			room->seats[s].kind = SEAT_AI;
			room->seats[s].fd = -1;
			return (s);
		}
		s++;
	}
	return (-1);
}

/*
** Whose move it is: the engine counts plies, the seats take them in order.
*/
int	seat_on_turn(t_room *room)
{
	if (room->seat_count <= 0)
		return (0);
	return ((int)(room->session.state.turn % (unsigned int)room->seat_count));
}

int	seat_owned_by(t_room *room, int seat, t_client *client)
{
	if (seat < 0 || seat >= room->seat_count)
		return (0);
	if (room->seats[seat].kind != SEAT_HUMAN)
		return (0);
	return (room->seats[seat].fd == client->fd);
}
