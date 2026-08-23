#ifndef ROOM_H
# define ROOM_H

# include "net.h"
# include "proto.h"
# include "engine.h"

/*
** Rooms, seats and teams.
**
** A room owns one board and a fixed number of seats. Seat parity is the team:
** even seats are black, odd seats are white, and the seat to play is
** turn % seat_count. That makes the rotation B1, W1, B2, W2 - teams alternate
** every ply, rotating within each team - so colour still alternates on every
** move and the engine needs no idea that any of this exists.
**
** Every mode is the same shape. Solo is two seats, one human and one AI.
** Hotseat is two seats owned by the same client. Multiplayer is two or four
** seats owned by different clients. Nothing downstream special cases them.
*/

# define MAX_ROOMS 16
# define MAX_SEATS 4
# define CODE_LEN 5
# define AI_TAKEOVER_SECONDS 60

typedef enum e_seat_kind
{
	SEAT_EMPTY,
	SEAT_HUMAN,
	SEAT_AI
}	t_seat_kind;

typedef struct s_seat
{
	t_seat_kind	kind;
	int			fd;
	long		vacated_at;
}	t_seat;

typedef struct s_room
{
	int			live;
	int			started;
	int			seat_count;
	int			admin_seat;
	char		code[CODE_LEN];
	t_seat		seats[MAX_SEATS];
	t_session	session;
}	t_room;

/* room_table.c */
void	room_reset_all(void);
t_room	*room_create(int seat_count);
t_room	*room_at(int index);
void	room_release(t_room *room);

/* room_lookup.c */
t_room	*room_by_code(const char *code);
t_room	*room_of_client(t_client *client);

/* room_seats.c */
int		seat_take(t_room *room, t_client *client);
void	seat_release_client(t_server *server, t_client *client);
int		seat_add_ai(t_room *room);
int		seat_on_turn(t_room *room);
int		seat_owned_by(t_room *room, int seat, t_client *client);

/* room_view.c */
const char	*seat_colour(int seat);
void		room_emit(t_server *server, t_room *room, const char *fmt, ...);
void		room_view_seats(t_server *server, t_room *room);
void		room_view_mine(t_server *server, t_room *room,
				t_client *client);

/* room_tick.c */
void	room_tick(t_server *server);
long	room_now(void);

#endif
