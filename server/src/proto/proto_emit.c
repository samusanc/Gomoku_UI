#include "proto.h"
#include <stdarg.h>
#include <stdio.h>

/*
** Format one event and send it to a single client. Framing is added here, so
** no caller ever writes a newline by hand. Over long lines are truncated.
*/
int	proto_emit(t_client *client, const char *fmt, ...)
{
	char	line[LINE_MAX_LEN];
	va_list	args;
	int		len;

	va_start(args, fmt);
	len = vsnprintf(line, sizeof(line) - 1, fmt, args);
	va_end(args);
	if (len < 0)
		return (-1);
	if (len > (int)sizeof(line) - 2)
		len = (int)sizeof(line) - 2;
	line[len] = '\n';
	line[len + 1] = '\0';
	return (client_send(client, line, (size_t)len + 1));
}

/*
** Same, to every connected UI. Used for anything that changes the position,
** so a second spectator window stays in sync for free.
*/
void	proto_broadcast(t_server *server, const char *fmt, ...)
{
	char	line[LINE_MAX_LEN];
	va_list	args;
	int		len;

	va_start(args, fmt);
	len = vsnprintf(line, sizeof(line) - 1, fmt, args);
	va_end(args);
	if (len < 0)
		return ;
	if (len > (int)sizeof(line) - 2)
		len = (int)sizeof(line) - 2;
	line[len] = '\n';
	line[len + 1] = '\0';
	client_broadcast(server, line, (size_t)len + 1);
}
