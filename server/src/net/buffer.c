#include "net.h"
#include <stdlib.h>
#include <string.h>

/*
** Append a chunk to a heap buffer. On allocation failure, or when the peer
** exceeds BUF_MAX_LEN without ever sending a newline, the old buffer is freed
** and NULL comes back: the caller drops that client, the process lives.
*/
char	*buf_append(char *buf, const char *add)
{
	char	*joined;
	size_t	len;
	size_t	add_len;

	len = 0;
	if (buf != NULL)
		len = strlen(buf);
	add_len = strlen(add);
	if (len + add_len > BUF_MAX_LEN)
	{
		free(buf);
		return (NULL);
	}
	joined = malloc(len + add_len + 1);
	if (joined == NULL)
	{
		free(buf);
		return (NULL);
	}
	if (buf != NULL)
		memcpy(joined, buf, len);
	memcpy(joined + len, add, add_len + 1);
	free(buf);
	return (joined);
}

/*
** Pull the first newline terminated line out of the buffer. The line comes
** back heap allocated, without its terminator and without a trailing CR.
** Returns 1 on success, 0 when no complete line is buffered, -1 on failure.
*/
int	buf_extract_line(char **buf, char **line)
{
	char	*newline;
	char	*rest;
	size_t	len;

	*line = NULL;
	if (*buf == NULL)
		return (0);
	newline = strchr(*buf, '\n');
	if (newline == NULL)
		return (0);
	len = (size_t)(newline - *buf);
	rest = strdup(newline + 1);
	if (len > 0 && (*buf)[len - 1] == '\r')
		len--;
	*line = malloc(len + 1);
	if (*line == NULL || rest == NULL)
	{
		free(*line);
		free(rest);
		*line = NULL;
		return (-1);
	}
	memcpy(*line, *buf, len);
	(*line)[len] = '\0';
	free(*buf);
	*buf = rest;
	return (1);
}
