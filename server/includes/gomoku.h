#ifndef GOMOKU_H
# define GOMOKU_H

# define BOARD_SIZE 19
# define CAPTURES_TO_WIN 10
# define ALIGN_TO_WIN 5

/*
** Cell states of a goban intersection.
*/
typedef enum e_cell
{
	CELL_EMPTY,
	CELL_BLACK,
	CELL_WHITE
}	t_cell;

/*
** Full game state: goban plus the capture counters of both players.
*/
typedef struct s_board
{
	t_cell	cells[BOARD_SIZE][BOARD_SIZE];
	int		captures_black;
	int		captures_white;
	t_cell	turn;
}	t_board;

void	board_init(t_board *board);

#endif
