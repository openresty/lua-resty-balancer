OPENRESTY_PREFIX=/usr/local/openresty-debug

PREFIX ?=          /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all test install bench

SRC := chash.c
OBJ := $(SRC:.c=.o)

C_SO_NAME := librestychash.so

CFLAGS := -O3 -g -Wall -fpic

LDFLAGS := -shared
# on Mac OS X, one should set instead:
# LDFLAGS := -bundle -undefined dynamic_lookup

ifeq ($(shell uname),Darwin)
	LDFLAGS := -bundle -undefined dynamic_lookup
	C_SO_NAME := librestychash.dylib
endif

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

test := t

.PHONY = all test clean install

all : $(C_SO_NAME)

${OBJ} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $<

${C_SO_NAME} : ${OBJ}
	$(CC) $(MY_LDFLAGS) $^ -o $@

#export TEST_NGINX_NO_CLEAN=1

clean:; rm -f *.o *.so a.out *.d

install:
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/resty
	$(INSTALL) -d $(DESTDIR)$(LUA_LIB_DIR)/resty/balancer
	$(INSTALL) lib/resty/*.lua $(DESTDIR)$(LUA_LIB_DIR)/resty
	$(INSTALL) lib/resty/balancer/*.lua $(DESTDIR)$(LUA_LIB_DIR)/resty/balancer
	$(INSTALL) $(C_SO_NAME) $(DESTDIR)$(LUA_LIB_DIR)/

test : all
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -I../test-nginx/lib -r $(test)

bench:
	$(OPENRESTY_PREFIX)/bin/resty t/bench-chash.lua `pwd`
	$(OPENRESTY_PREFIX)/bin/resty t/bench-roundrobin.lua `pwd`
