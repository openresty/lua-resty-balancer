OPENRESTY_PREFIX=/usr/local/openresty-debug

PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all test install bench

SRC := chash.c
OBJ := $(SRC:.c=.o)

C_SO_NAME := librestychash.so

CFLAGS := -Wall -O3 -flto -g -DFP_RELAX=0 -DDEBUG
THE_CFLAGS := $(CFLAGS) -fPIC -MMD -fvisibility=hidden

test := t

.PHONY = all test clean install

all : $(C_SO_NAME)

${OBJ} : %.o : %.c
	$(CC) $(THE_CFLAGS) -DBUILDING_SO -c $<

${C_SO_NAME} : ${OBJ}
	$(CC) $(THE_CFLAGS) -DBUILDING_SO $^ -shared -o $@

#export TEST_NGINX_NO_CLEAN=1

clean:; rm -f *.o *.so a.out *.d

install:
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/resty
	$(INSTALL) lib/resty/*.lua $(DESTDIR)$(LUA_LIB_DIR)/resty
	$(INSTALL) $(C_SO_NAME) $(DESTDIR)$(LUA_LIB_DIR)/

test : all
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -I../test-nginx/lib -r $(test)

bench:
	$(OPENRESTY_PREFIX)/bin/resty t/bench.lua
