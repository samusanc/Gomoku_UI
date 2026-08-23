#include "room.h"
#include <stdarg.h>
#include <stdio.h>

/*
** Seat parity is the team. Even seats are black, which also makes the seat on
** turn agree with the engine, where black plays the even plies.
*/
const char	*seat_colour(int seat)
{
	if (seat % 2 == 0)
		return ("B");
	return ("W");
}

/*
** Same as proto_broadcast but scoped to one room, so two games on the same
** server never see each other.
*/
void	room_emit(t_server *server, t_room *room, const char *fmt, ...)
{
	char	line[LINE_MAX_LEN];
	va_list	args;
	int		len;
	int		s;

	va_start(args, fmt);
	len = vsnprintf(line, sizeof(line) - 1, fmt, args);
	va_end(args);
	if (len < 0 || room == NULL)
		return ;
	if (len > (int)sizeof(line) - 2)
		len = (int)sizeof(line) - 2;
	line[len] = '\n';
	line[len + 1] = '\0';
	s = 0;
	while (s < room->seat_count)
	{
		if (room->seats[s].kind == SEAT_HUMAN && room->seats[s].fd >= 0
			&& room->seats[s].fd < FD_SETSIZE)
			client_send(&server->clients[room->seats[s].fd], line,
				(size_t)len + 1);
		s++;
	}
}

static const char	*seat_kind_name(t_seat_kind kind)
{
	if (kind == SEAT_HUMAN)
		return ("human");
	if (kind == SEAT_AI)
		return ("ai");
	return ("empty");
}

/*
** The lobby roster. One SEAT line per seat so a client can render the list
** without parsing a variable length field.
*/
void	room_view_seats(t_server *server, t_room *room)
{
	int	s;

	if (room == NULL)
		return ;
	room_emit(server, room, "ROOM %s %d %d %d", room->code, room->seat_count,
		room->admin_seat, room->started);
	s = 0;
	while (s < room->seat_count)
	{
		room_emit(server, room, "SEAT %d %s %s %d", s,
			seat_kind_name(room->seats[s].kind), seat_colour(s),
			room->seats[s].fd);
		s++;
	}
}
