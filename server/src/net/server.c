#include "net.h"
#include <errno.h>
#include <netinet/in.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>

/*
** Bind and listen on the loopback interface only. Returns -1 on any failure
** so main can report it and exit; nothing here kills the process itself.
*/
int	server_init(t_server *server, int port)
{
	struct sockaddr_in	addr;
	int					opt;

	memset(server, 0, sizeof(*server));
	FD_ZERO(&server->active);
	signal(SIGPIPE, SIG_IGN);
	server->listen_fd = socket(AF_INET, SOCK_STREAM, 0);
	if (server->listen_fd < 0)
		return (-1);
	opt = 1;
	setsockopt(server->listen_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
	memset(&addr, 0, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	addr.sin_port = htons((unsigned short)port);
	if (bind(server->listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
		return (-1);
	if (listen(server->listen_fd, SOMAXCONN) < 0)
		return (-1);
	FD_SET(server->listen_fd, &server->active);
	server->max_fd = server->listen_fd;
	return (0);
}

/*
** Single threaded select loop. It only ever returns on a fatal select error;
** a misbehaving client is dropped, never fatal.
*/
int	server_run(t_server *server)
{
	fd_set	read_set;
	int		fd;

	while (1)
	{
		read_set = server->active;
		if (select(server->max_fd + 1, &read_set, NULL, NULL, NULL) < 0)
		{
			if (errno == EINTR)
				continue ;
			return (-1);
		}
		fd = 0;
		while (fd <= server->max_fd)
		{
			if (FD_ISSET(fd, &read_set) && fd == server->listen_fd)
				server_accept(server);
			else if (FD_ISSET(fd, &read_set) && server->clients[fd].alive == 1)
				server_read(server, fd);
			fd++;
		}
	}
	return (0);
}

/*
** Release every descriptor and every pending buffer.
*/
void	server_shutdown(t_server *server)
{
	int	fd;

	fd = 0;
	while (fd < FD_SETSIZE)
	{
		if (server->clients[fd].alive == 1)
			client_remove(server, fd);
		fd++;
	}
	if (server->listen_fd >= 0)
		close(server->listen_fd);
	server->listen_fd = -1;
}
