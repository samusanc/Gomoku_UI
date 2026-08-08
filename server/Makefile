NAME		= gomoku_server

#=============================== INCLUDES ===============================#

INC			= -I./includes/

#============================== LIBRARIES ===============================#

# SUBMODLIB	= ./libft/libft.a

#================================= GCC ==================================#

CFLAGS		= -Wall -Wextra -Werror
CFLAGS	   += -O2
# CFLAGS	   += -fsanitize=address
CC			= gcc $(CFLAGS) $(INC)

#================================= SRCS =================================#

SRCS		= \
				./src/main.c \
				./src/board/board.c \
				./src/net/buffer.c \
				./src/net/client.c \
				./src/net/server.c \
				./src/net/server_io.c \
				./src/proto/proto_parse.c \
				./src/proto/proto_emit.c \
				./src/engine/engine_stub.c \
				./src/engine/engine_stub_cmds.c \
				./src/engine/engine_stub_view.c \

#================================= OBJS =================================#

O_DIR		= ./objects
OBJS		= $(addprefix $(O_DIR)/, $(SRCS:.c=.o))

#========================================================================#

$(O_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) -g -c $< -o $(O_DIR)/$(<:.c=.o)

all: $(NAME)

#======================= MANDATORY AND BONUS =========================#

# The binary depends on the objects directly: it relinks when a source
# changed and stays untouched otherwise, so a second `make` is a no-op.
$(NAME): $(OBJS)
	$(CC) -o $(NAME) $(OBJS)
	@echo "mandatory done..."

#============================== CLEANING =============================#

re: fclean all

fclean: clean
	@echo "cleaning binaries..."
	@rm -f $(NAME)

clean:
	@echo "cleaning objects..."
	@rm -f $(OBJS)
	@rm -rf $(O_DIR)

.PHONY: all clean fclean re
