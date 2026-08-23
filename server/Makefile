NAME		= gomoku_server

#=============================== INCLUDES ===============================#

INC			= -I./includes/
INC		   += -I./ai_engine/

#================================= GCC ==================================#

CFLAGS		= -Wall -Wextra -Werror
CFLAGS	   += -O2
# CFLAGS	   += -fsanitize=address
CC			= gcc $(CFLAGS) $(INC)

#================================= SRCS =================================#

SRCS		= \
				./src/main.c \
				./src/net/buffer.c \
				./src/net/client.c \
				./src/net/server.c \
				./src/net/server_io.c \
				./src/proto/proto_parse.c \
				./src/proto/proto_emit.c \
				./src/engine/engine_ai.c \
				./src/engine/engine_dispatch.c \
				./src/engine/engine_cmds.c \
				./src/engine/engine_move.c \
				./src/engine/engine_search.c \
				./src/engine/engine_view.c 				./src/engine/engine_rooms.c 				./src/room/room_table.c 				./src/room/room_lookup.c 				./src/room/room_seats.c 				./src/room/room_view.c 				./src/room/room_tick.c \

#============================= AI ENGINE ================================#

# Submodule owned by the engine team (server/ai_engine). Their gomoku.c holds
# a self-play main and connect.c is an unrelated connect-four leftover, so
# both stay out. Listed explicitly, never globbed, so a new engine file is a
# deliberate change here rather than a silent one.
AI_SRCS		= \
				ai_engine/game.c \
				ai_engine/game_eval.c \
				ai_engine/game_moves.c \
				ai_engine/game_render.c \
				ai_engine/game_rules.c \
				ai_engine/game_score.c \
				ai_engine/game_updates.c \
				ai_engine/helpers.c \
				ai_engine/negamax.c \

# Their code is warning clean today, but it is not ours to keep that way: we
# still want to SEE their warnings, without our build failing on them.
AI_CFLAGS	= -Wall -Wextra -O2

#================================= OBJS =================================#

O_DIR		= ./objects
OBJS		= $(addprefix $(O_DIR)/, $(SRCS:.c=.o))
AI_OBJS		= $(addprefix $(O_DIR)/, $(AI_SRCS:.c=.o))

#========================================================================#

$(O_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) -g -c $< -o $(O_DIR)/$(<:.c=.o)

$(O_DIR)/ai_engine/%.o: ai_engine/%.c
	@mkdir -p $(@D)
	gcc $(AI_CFLAGS) $(INC) -g -c $< -o $@

all: submodules $(NAME)

#============================= SUBMODULES ===============================#

# A fresh clone has an empty ai_engine/; pull it in rather than failing with a
# confusing missing-header error.
submodules:
	@if [ ! -f ./ai_engine/gomoku.h ]; then \
		echo "ai_engine submodule missing, initialising..."; \
		git -C .. submodule update --init --recursive; \
	fi

#======================= MANDATORY AND BONUS =========================#

# The binary depends on the objects directly: it relinks when a source
# changed and stays untouched otherwise, so a second `make` is a no-op.
$(NAME): $(OBJS) $(AI_OBJS)
	$(CC) -o $(NAME) $(OBJS) $(AI_OBJS)
	@echo "mandatory done..."

#============================== CLEANING =============================#

re: fclean all

fclean: clean
	@echo "cleaning binaries..."
	@rm -f $(NAME)

clean:
	@echo "cleaning objects..."
	@rm -f $(OBJS) $(AI_OBJS)
	@rm -rf $(O_DIR)

.PHONY: all clean fclean re submodules
