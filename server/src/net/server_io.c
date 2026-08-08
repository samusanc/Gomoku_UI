#include "net.h"
#include "proto.h"
#include "engine.h"
#include <stdlib.h>
#include <sys/socket.h>
#include <unistd.h>

/*
** Take one pending connection. A descriptor select cannot watch is closed
** immediately rather than corrupting the table.
*/
void	server_accept(t_server *server)
{
	int	fd;

	fd = accept(server->listen_fd, NULL, NULL);
	if (fd < 0)
		return ;
	if (client_add(server, fd) < 0)
	{
		close(fd);
		return ;
	}
	engine_client_join(server, &server->clients[fd]);
}

/*
** Tokenize one line and hand it to the engine seam. The server itself never
** looks at what the verb means.
*/
void	server_dispatch(t_server *server, int fd, char *line)
{
	t_cmd	cmd;

	if (proto_parse(line, &cmd) == 0)
		return ;
	engine_handle(server, &server->clients[fd], &cmd);
}

/*
** Drain one readable client, framing whatever arrived into whole lines. Any
** allocation failure drops that single client instead of ending the process.
*/
void	server_read(t_server *server, int fd)
{
	char		chunk[READ_CHUNK + 1];
	t_client	*client;
	char		*line;
	ssize_t		count;
	int			status;

	client = &server->clients[fd];
	count = recv(fd, chunk, READ_CHUNK, 0);
	if (count <= 0)
	{
		engine_client_leave(server, client);
		client_remove(server, fd);
		return ;
	}
	chunk[count] = '\0';
	client->pending = buf_append(client->pending, chunk);
	status = 0;
	if (client->pending != NULL)
		status = buf_extract_line(&client->pending, &line);
	while (status == 1)
	{
		server_dispatch(server, fd, line);
		free(line);
		if (client->alive == 0)
			return ;
		status = buf_extract_line(&client->pending, &line);
	}
	if (status < 0 || client->pending == NULL)
		client_remove(server, fd);
}
