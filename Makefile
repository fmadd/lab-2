APP_NAME ?= minmax_asm

SRC_DIR := src
BIN_DIR := bin
OBJ_DIR := $(BIN_DIR)/obj

CC   := gcc
NASM := nasm

BUILD ?= release

compile_flags ?=
override compile_flags += -pipe

ifeq ($(BUILD),debug)
  CFLAGS_BASE := -O0 -g -DDEBUG
else
  CFLAGS_BASE := -O2 -DNDEBUG
endif

CPPFLAGS := -I$(SRC_DIR)
CFLAGS   := -std=c11 -Wall -Wextra -Wpedantic $(CFLAGS_BASE) $(compile_flags)
LDFLAGS  :=

UNAME_S := $(shell uname -s 2>/dev/null || echo Unknown)
ifeq ($(UNAME_S),Linux)
  NASM_FORMAT := elf64
else ifeq ($(UNAME_S),Darwin)
  NASM_FORMAT := macho64
else
  $(warning Неподдерживаемая ось '$(UNAME_S)')
  NASM_FORMAT := elf64
endif

SRCS_C   := $(wildcard $(SRC_DIR)/*.c)
SRCS_ASM := $(wildcard $(SRC_DIR)/*.asm)

OBJS_C   := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS_C))
OBJS_ASM := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SRCS_ASM))
OBJS     := $(OBJS_C) $(OBJS_ASM)

DEPS := $(OBJS_C:.o=.d)

.PHONY: all
all: $(BIN_DIR)/$(APP_NAME)

$(BIN_DIR)/$(APP_NAME): $(OBJS) | $(BIN_DIR)
	$(CC) $(OBJS) $(LDFLAGS) -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) -MMD -MP -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm | $(OBJ_DIR)
	$(NASM) -f $(NASM_FORMAT) $(ASMFLAGS) $< -o $@

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

RUN_ARGS ?= 4 5 -100 100
.PHONY: run
run: all
	$(BIN_DIR)/$(APP_NAME) $(RUN_ARGS)

.PHONY: clean
clean:
	-$(RM) -r $(OBJ_DIR) *.o *.d

.PHONY: distclean
distclean: clean
	-$(RM) -r $(BIN_DIR)

.PHONY: debug release
debug:
	$(MAKE) BUILD=debug

release:
	$(MAKE) BUILD=release

.PHONY: help
help:
	@echo "Targets:"
	@echo "  make [all]          - собрать"
	@echo "  make run            - собрать и запустить (RUN_ARGS=\"M N [min max]\")"
	@echo "  make clean          - очистить obj и *.d"
	@echo "  make distclean      - очистить bin/"
	@echo "  make debug|release  - сборка с нужным профилем"
	@echo "Variables:"
	@echo "  BUILD=debug|release"
	@echo "  RUN_ARGS=\"4 5 -100 100\""
	@echo "  compile_flags=\"-fsanitize=address -fno-omit-frame-pointer\""

-include $(DEPS)
