OPENRESTY_PREFIX=/usr/local/openresty-debug

PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all test install bench

OS := $(shell uname)

SRC := chash.c
OBJ := $(SRC:.c=.o)

ifeq ($(OS), Darwin)
C_SO_NAME := libchash.dylib
else
C_SO_NAME := libchash.so
endif

CFLAGS := -Wall -O3 -flto -g -DFP_RELAX=0 -DDEBUG
THE_CFLAGS := $(CFLAGS) -fPIC -MMD -fvisibility=hidden

.PHONY = all test clean install

all : $(C_SO_NAME)

${OBJ} : %.o : %.c
	$(CC) $(THE_CFLAGS) -DBUILDING_SO -c $<

${C_SO_NAME} : ${OBJ}
	$(CC) $(THE_CFLAGS) -DBUILDING_SO $^ -shared -o $@

clean:; rm -f *.o *.so a.out *.d

install:
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/resty
	$(INSTALL) lib/resty/*.lua $(DESTDIR)$(LUA_LIB_DIR)/resty
	$(INSTALL) $(C_SO_NAME) $(DESTDIR)$(LUA_LIB_DIR)/

test : all
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -I../test-nginx/lib -r t/chash.t

bench:
	$(OPENRESTY_PREFIX)/bin/resty t/bench.lua
