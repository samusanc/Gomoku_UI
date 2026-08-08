#include "net.h"
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>

/*
** Take a freshly accepted descriptor into the client table. Returns -1 when
** the descriptor is outside what select can watch.
*/
int	client_add(t_server *server, int fd)
{
	t_client	*client;

	if (fd < 0 || fd >= FD_SETSIZE)
		return (-1);
	client = &server->clients[fd];
	client->fd = fd;
	client->id = server->next_id++;
	client->alive = 1;
	client->debug = 0;
	client->pending = NULL;
	FD_SET(fd, &server->active);
	if (fd > server->max_fd)
		server->max_fd = fd;
	return (0);
}

/*
** Close a client and shrink max_fd back down so select stays cheap. Safe to
** call twice on the same descriptor.
*/
void	client_remove(t_server *server, int fd)
{
	t_client	*client;

	if (fd < 0 || fd >= FD_SETSIZE)
		return ;
	client = &server->clients[fd];
	if (client->alive == 0)
		return ;
	FD_CLR(fd, &server->active);
	free(client->pending);
	client->pending = NULL;
	client->alive = 0;
	close(fd);
	while (server->max_fd > server->listen_fd
		&& FD_ISSET(server->max_fd, &server->active) == 0)
		server->max_fd--;
}

/*
** Write a whole buffer to one socket, tolerating partial sends. Returns -1
** when the peer is gone so the caller can drop it.
*/
int	client_send(t_client *client, const char *data, size_t len)
{
	ssize_t	sent;
	size_t	offset;

	if (client->alive == 0)
		return (-1);
	offset = 0;
	while (offset < len)
	{
		sent = send(client->fd, data + offset, len - offset, MSG_NOSIGNAL);
		if (sent < 0 && errno == EINTR)
			continue ;
		if (sent <= 0)
			return (-1);
		offset += (size_t)sent;
	}
	return (0);
}

/*
** Push a line to every connected UI. Dead peers are reaped on the way.
*/
void	client_broadcast(t_server *server, const char *data, size_t len)
{
	int	fd;

	fd = 0;
	while (fd <= server->max_fd)
	{
		if (fd != server->listen_fd && server->clients[fd].alive == 1)
		{
			if (client_send(&server->clients[fd], data, len) < 0)
				client_remove(server, fd);
		}
		fd++;
	}
}
