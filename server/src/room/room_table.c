#include "room.h"
#include <stdlib.h>
#include <string.h>
#include <time.h>

static t_room	g_rooms[MAX_ROOMS];

void	room_reset_all(void)
{
	memset(g_rooms, 0, sizeof(g_rooms));
	srand((unsigned int)time(NULL));
}

/*
** Four characters from an alphabet with no 0/O or 1/I, so a code read out
** loud cannot be mistyped.
*/
static void	room_make_code(char *out)
{
	static const char	*alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
	int					i;

	i = 0;
	while (i < CODE_LEN - 1)
	{
		out[i] = alphabet[rand() % 32];
		i++;
	}
	out[i] = '\0';
}

t_room	*room_create(int seat_count)
{
	int	i;

	if (seat_count != 2 && seat_count != 4)
		return (NULL);
	i = 0;
	while (i < MAX_ROOMS)
	{
		if (g_rooms[i].live == 0)
		{
			memset(&g_rooms[i], 0, sizeof(t_room));
			g_rooms[i].live = 1;
			g_rooms[i].seat_count = seat_count;
			g_rooms[i].admin_seat = -1;
			initialize_game_state(&g_rooms[i].session.state);
			g_rooms[i].session.ai_side = SIDE_NONE;
			room_make_code(g_rooms[i].code);
			return (&g_rooms[i]);
		}
		i++;
	}
	return (NULL);
}

t_room	*room_at(int index)
{
	if (index < 0 || index >= MAX_ROOMS)
		return (NULL);
	return (&g_rooms[index]);
}

void	room_release(t_room *room)
{
	if (room == NULL)
		return ;
	memset(room, 0, sizeof(t_room));
}
