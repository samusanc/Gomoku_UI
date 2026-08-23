#ifndef ENGINE_H
# define ENGINE_H

# include "net.h"
# include "proto.h"
# include "gomoku.h"

typedef struct s_room	t_room;

/*
** Seam between the transport layer and the AI engine.
**
** The engine is the submodule in server/ai_engine, owned by the engine team.
** It holds the board, the rules and the search. This layer only translates:
** protocol line in, engine call out, protocol events back. No rule, no
** evaluation and no search ever belongs here or in src/net/ and src/proto/.
*/

/*
** Sides, in the engine's own convention: it stores black as a positive cell
** and white as negative, and black moves on even turns.
*/
# define SIDE_BLACK 0
# define SIDE_WHITE 1
# define SIDE_NONE (-1)

# define SCORE_INF 10000000

/*
** The engine's search takes a fixed depth and cannot be interrupted, so the
** wrapper deepens one ply at a time and stops before it would blow the
** subject's half second. GROWTH is how much more expensive the next ply is
** assumed to be, measured at roughly 6x to 12x on the current engine.
*/
# define AI_BUDGET_MS 400
# define AI_MAX_DEPTH 12
# define AI_GROWTH 10

typedef struct s_search_result
{
	int	move;
	int	depth;
	int	score;
	int	ms;
}	t_search_result;

/*
** Per room game state. It no longer carries an ai_side: which seats are AI is
** the room's business, and a seat already knows its colour.
*/
typedef struct s_session
{
	t_game_state	state;
	int				active;
	int				finished;
	int				ai_side;
	char			mode[8];
	char			ruleset[16];
}	t_session;

int		engine_init(t_server *server);
void	engine_shutdown(t_server *server);
void	engine_client_join(t_server *server, t_client *client);
void	engine_client_leave(t_server *server, t_client *client);
void	engine_handle(t_server *server, t_client *client, t_cmd *cmd);
void	engine_tick(t_server *server);

/* engine_view.c */
const char	*side_name(int side);
int			side_to_move(t_session *session);
void		view_board(t_server *server, t_room *room);
void		view_snapshot(t_server *server, t_room *room);
void		view_turn(t_server *server, t_room *room);

/* engine_move.c */
void	move_apply(t_server *server, t_room *room, int move);
int		move_report_end(t_server *server, t_room *room);
void	cmd_move(t_server *server, t_client *client, t_cmd *cmd);

/* engine_search.c */
void	engine_search(t_session *session, t_search_result *result);
void	engine_advance(t_server *server, t_room *room);
void	cmd_suggest(t_server *server, t_client *client);

/* engine_cmds.c */
void	cmd_new(t_server *server, t_client *client, t_cmd *cmd);
void	cmd_state(t_server *server, t_client *client);
void	cmd_resign(t_server *server, t_client *client);

/* engine_rooms.c */
void	cmd_create(t_server *server, t_client *client, t_cmd *cmd);
void	cmd_join(t_server *server, t_client *client, t_cmd *cmd);
void	cmd_addai(t_server *server, t_client *client);
void	cmd_begin(t_server *server, t_client *client);
void	cmd_leave(t_server *server, t_client *client);

#endif
