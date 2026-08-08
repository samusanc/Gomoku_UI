#ifndef ENGINE_H
# define ENGINE_H

# include "net.h"
# include "proto.h"
# include "gomoku.h"

/*
** Seam between the transport layer and the real game logic plus AI.
**
** The server parses a line, hands it to engine_handle, and whatever this layer
** emits goes back out as protocol events. No rule, no search and no evaluation
** ever belongs in src/net/ or src/proto/. Replacing the stub implementation
** must not require a single change there.
*/

/*
** Scaffolding state held by the stub only. The real engine is free to define
** its own session type; only the five entry points below are contractual.
*/
typedef struct s_session
{
	t_board	board;
	int		active;
	int		move_no;
	t_cell	ai_color;
	char	mode[8];
	char	ruleset[16];
}	t_session;

int		engine_init(t_server *server);
void	engine_shutdown(t_server *server);
void	engine_client_join(t_server *server, t_client *client);
void	engine_client_leave(t_server *server, t_client *client);
void	engine_handle(t_server *server, t_client *client, t_cmd *cmd);

void	stub_new(t_server *server, t_client *client, t_cmd *cmd, t_session *s);
void	stub_move(t_server *server, t_client *client, t_cmd *cmd, t_session *s);
void	stub_suggest(t_server *server, t_client *client, t_cmd *cmd,
			t_session *s);
void	stub_state(t_server *server, t_client *client, t_cmd *cmd,
			t_session *s);

void	stub_send_board(t_server *server, t_board *board);
void	stub_send_snapshot(t_server *server, t_session *session);

#endif
