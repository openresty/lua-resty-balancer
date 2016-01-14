Name
====

lua-resty-chash

Table of Contents
=================

* [Name](#name)
* [Synopsis](#synopsis)
* [Description](#description)
* [Methods](#methods)
    * [new](#new)
    * [reinit](#reinit)
    * [set](#set)
    * [delete](#delete)
    * [up](#up)
    * [down](#down)
    * [find](#find)
    * [simple_find](#simple_find)

Synopsis
========


Description
===========

Methods
=======

new
---
**syntax:** `obj, err = class.new(nodes)`

Instantiates an object of this class. The `class` value is returned by the call `require "resty.chash"`.

```lua
local nodes = {
    -- id => weight
    server1 = 10,
    server2 = 2,
}

local resty_chash = require "resty.chash"

local chash = resty_chash:new(nodes)

local id = chash:find("foo")

ngx.say(id)
```

[Back to TOC](#table-of-contents)

reinit
--------
**syntax:** `obj:reinit(nodes)`

[Back to TOC](#table-of-contents)

set
--------
**syntax:** `obj:set(id, weight)`

[Back to TOC](#table-of-contents)

delete
--------
**syntax:** `obj:delete(id)`

[Back to TOC](#table-of-contents)

up
--------
**syntax:** `obj:set(id, weight?)`

[Back to TOC](#table-of-contents)

down
--------
**syntax:** `obj:down(id, weight?)`

[Back to TOC](#table-of-contents)

find
--------
**syntax:** `id = obj:find(key)`

[Back to TOC](#table-of-contents)

simple_find
--------
**syntax:** `id = obj:simple_find(key)`

[Back to TOC](#table-of-contents)

