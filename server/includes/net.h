#ifndef NET_H
# define NET_H

# include <stddef.h>
# include <sys/select.h>
# include <sys/socket.h>

# define READ_CHUNK 1024
# define LINE_MAX_LEN 4096

/*
** Hard cap on what one client may buffer without ever sending a newline.
** Past it the client is dropped, so a peer cannot grow the heap without bound.
*/
# define BUF_MAX_LEN (LINE_MAX_LEN * 4)

/*
** Not defined on every platform; sending with 0 flags is the fallback and
** SIGPIPE is ignored process wide anyway.
*/
# ifndef MSG_NOSIGNAL
#  define MSG_NOSIGNAL 0
# endif

/*
** One connected UI. Clients are indexed by their own file descriptor, so the
** array slot and the fd are always the same number.
*/
typedef struct s_client
{
	int		fd;
	int		id;
	int		alive;
	int		debug;
	char	*pending;
}	t_client;

typedef struct s_server
{
	int			listen_fd;
	int			max_fd;
	int			next_id;
	fd_set		active;
	t_client	clients[FD_SETSIZE];
}	t_server;

int		server_init(t_server *server, int port);
int		server_run(t_server *server);
void	server_shutdown(t_server *server);

void	server_accept(t_server *server);
void	server_read(t_server *server, int fd);
void	server_dispatch(t_server *server, int fd, char *line);

int		client_add(t_server *server, int fd);
void	client_remove(t_server *server, int fd);
int		client_send(t_client *client, const char *data, size_t len);
void	client_broadcast(t_server *server, const char *data, size_t len);

char	*buf_append(char *buf, const char *add);
int		buf_extract_line(char **buf, char **line);

#endif
