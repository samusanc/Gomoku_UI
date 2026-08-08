#include "net.h"
#include "engine.h"
#include <stdio.h>
#include <stdlib.h>

/*
** Strict port parsing: anything that is not a whole number in range is refused
** rather than silently becoming zero.
*/
static int	parse_port(const char *arg)
{
	long	value;
	char	*end;

	value = strtol(arg, &end, 10);
	if (*arg == '\0' || *end != '\0' || value < 1 || value > 65535)
		return (-1);
	return ((int)value);
}

int	main(int argc, char **argv)
{
	static t_server	server;
	int				port;

	if (argc != 2)
	{
		fprintf(stderr, "usage: gomoku_server <port>\n");
		return (1);
	}
	port = parse_port(argv[1]);
	if (port < 0)
	{
		fprintf(stderr, "gomoku_server: invalid port '%s'\n", argv[1]);
		return (1);
	}
	if (server_init(&server, port) < 0)
	{
		fprintf(stderr, "gomoku_server: cannot listen on port %d\n", port);
		server_shutdown(&server);
		return (1);
	}
	engine_init(&server);
	fprintf(stderr, "gomoku_server: listening on 127.0.0.1:%d\n", port);
	if (server_run(&server) < 0)
		fprintf(stderr, "gomoku_server: select failed\n");
	engine_shutdown(&server);
	server_shutdown(&server);
	return (0);
}
