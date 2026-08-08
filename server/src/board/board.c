#include "gomoku.h"

/*
** Reset the goban to an empty state, black to play first.
*/
void	board_init(t_board *board)
{
	int	y;
	int	x;

	y = 0;
	while (y < BOARD_SIZE)
	{
		x = 0;
		while (x < BOARD_SIZE)
		{
			board->cells[y][x] = CELL_EMPTY;
			x++;
		}
		y++;
	}
	board->captures_black = 0;
	board->captures_white = 0;
	board->turn = CELL_BLACK;
}
