#include "room.h"
#include <string.h>

/*
** The room table is private to room_table.c, so both lookups walk it through
** room_at rather than reaching for the array.
*/
t_room	*room_by_code(const char *code)
{
	t_room	*room;
	int		i;

	i = 0;
	while (i < MAX_ROOMS)
	{
		room = room_at(i);
		if (room->live == 1 && strcmp(room->code, code) == 0)
			return (room);
		i++;
	}
	return (NULL);
}

/*
** A client is in whichever room holds a seat with its descriptor. Hotseat puts
** the same descriptor in more than one seat, which is fine: it is one room.
*/
t_room	*room_of_client(t_client *client)
{
	t_room	*room;
	int		i;
	int		s;

	i = 0;
	while (i < MAX_ROOMS)
	{
		room = room_at(i);
		s = 0;
		while (room->live == 1 && s < room->seat_count)
		{
			if (room->seats[s].kind == SEAT_HUMAN
				&& room->seats[s].fd == client->fd)
				return (room);
			s++;
		}
		i++;
	}
	return (NULL);
}
