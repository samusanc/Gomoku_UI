#include "room.h"
#include <sys/time.h>

long	room_now(void)
{
	struct timeval	t;

	gettimeofday(&t, NULL);
	return ((long)t.tv_sec);
}

/*
** Called once a second from the accept loop. A seat whose human has been gone
** for AI_TAKEOVER_SECONDS becomes an AI and keeps the seat for the rest of the
** game; a returning player does not get it back.
*/
void	room_tick(t_server *server)
{
	t_room	*room;
	int		i;
	int		s;
	int		changed;

	i = 0;
	while (i < MAX_ROOMS)
	{
		room = room_at(i);
		changed = 0;
		s = 0;
		while (room->live == 1 && s < room->seat_count)
		{
			if (room->seats[s].kind == SEAT_HUMAN && room->seats[s].fd < 0
				&& room_now() - room->seats[s].vacated_at
				>= AI_TAKEOVER_SECONDS)
			{
				room->seats[s].kind = SEAT_AI;
				room->seats[s].vacated_at = 0;
				changed = 1;
			}
			s++;
		}
		if (changed == 1)
		{
			room_view_seats(server, room);
			engine_advance(server, room);
		}
		i++;
	}
}
