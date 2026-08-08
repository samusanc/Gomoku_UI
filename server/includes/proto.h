#ifndef PROTO_H
# define PROTO_H

# include "net.h"

# define PROTO_VERSION 1
# define PROTO_MAX_TOKENS 16

/*
** A parsed client line. argv points into the line buffer itself, so a t_cmd
** is only valid for as long as that buffer lives.
*/
typedef struct s_cmd
{
	int		argc;
	char	*argv[PROTO_MAX_TOKENS];
}	t_cmd;

int			proto_parse(char *line, t_cmd *cmd);
const char	*proto_arg(t_cmd *cmd, int index);
int			proto_is(t_cmd *cmd, const char *verb);

int			proto_emit(t_client *client, const char *fmt, ...);
void		proto_broadcast(t_server *server, const char *fmt, ...);

#endif
