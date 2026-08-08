#include "proto.h"
#include <string.h>

/*
** Split a line in place into space separated tokens. Tokens past the limit are
** dropped, so a hostile peer cannot grow the argv array.
*/
int	proto_parse(char *line, t_cmd *cmd)
{
	char	*token;
	char	*save;

	cmd->argc = 0;
	token = strtok_r(line, " \t", &save);
	while (token != NULL && cmd->argc < PROTO_MAX_TOKENS)
	{
		cmd->argv[cmd->argc] = token;
		cmd->argc++;
		token = strtok_r(NULL, " \t", &save);
	}
	return (cmd->argc);
}

/*
** Missing arguments read as the empty string, so handlers never branch on NULL.
*/
const char	*proto_arg(t_cmd *cmd, int index)
{
	if (index < 0 || index >= cmd->argc)
		return ("");
	return (cmd->argv[index]);
}

int	proto_is(t_cmd *cmd, const char *verb)
{
	if (cmd->argc == 0)
		return (0);
	return (strcmp(cmd->argv[0], verb) == 0);
}
