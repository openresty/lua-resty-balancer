
package.path = "/home/dou/work/git/doujiang/lua-resty-balancer-hash/lib/?.lua;" .. package.path
package.cpath = "/home/dou/work/git/doujiang/lua-resty-balancer-hash/?.so;" .. package.cpath

-- ngx.say(package.path); ngx.exit(200)

local function run_find(chash)
    local res = {}
    for i = 1, 100 * 1000 do
        local id = chash:find(i)

        if res[id] then
            res[id] = res[id] + 1
        else
            res[id] = 1
        end
    end

    for id, num in pairs(res) do
        ngx.say(id, ": ", num)
    end

    ngx.say("points number: ", chash.npoints)
end

local function run_simple_find(chash)
    local res = {}
    for i = 1, 100 * 1000 do
        local id = chash:simple_find(i)

        if res[id] then
            res[id] = res[id] + 1
        else
            res[id] = 1
        end
    end

    for id, num in pairs(res) do
        ngx.say(id, ": ", num)
    end

    ngx.say("points number: ", chash.npoints)
end

local function dump(chash)
    local last_hash = 0
    for i = 0, chash.npoints - 1 do
        local p = chash.points[i]

        ngx.say(p.hash, " : ", p.id)

        if p.hash < last_hash then
            error("wrong hash order")
        end

        last_hash = p.hash
    end
end


local base_time

-- should run typ = nil first
local function bench(num, name, func, typ, ...)
    ngx.update_time()
    local start = ngx.now()

    for i = 1, num do
        func(...)
    end

    ngx.update_time()
    local elasped = ngx.now() - start

    if typ then
        elasped = elasped - base_time
    end

    ngx.say(name)
    ngx.say(num, " times")
    ngx.say("elasped: ", elasped)
    ngx.say("")

    if not typ then
        base_time = elasped
    end
end


local resty_chash = require "resty.chash"

local servers = {
    ["server1"] = 10,
    ["server2"] = 2,
    ["server3"] = 1,
}

local servers2 = {
    ["server1"] = 100,
    ["server2"] = 20,
    ["server3"] = 10,
}

local chash = resty_chash:new(servers)
local chash2 = resty_chash:new2(servers)

local function gen_func(typ)
    local i = 0

    if typ == 0 then
        return function ()
            i = i + 1

            resty_chash:new(servers)
        end
    end

    if typ == 1 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
        end
    end

    if typ == 2 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:up("server3" .. i)
        end, typ
    end

    if typ == 3 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:up("server1" .. i)
        end, typ
    end

    if typ == 4 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:down("server1" .. i)
        end, typ
    end

    if typ == 5 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:delete("server3" .. i)
        end, typ
    end

    if typ == 6 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:delete("server1" .. i)
        end, typ
    end

    if typ == 7 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:set("server1" .. i, 9)
        end, typ
    end

    if typ == 8 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:set("server1" .. i, 8)
        end, typ
    end

    if typ == 9 then
        return function ()
            i = i + 1

            local servers = {
                ["server1" .. i] = 10,
                ["server2" .. i] = 2,
                ["server3" .. i] = 1,
            }
            local chash = resty_chash:new(servers)
            chash:set("server1" .. i, 1)
        end, typ
    end

    if typ == 100 then
        return function ()
            i = i + 1
        end
    end

    if typ == 101 then
        return function ()
            i = i + 1

            chash:find(i)
            i = i + 1
        end, typ
    end

    if typ == 102 then
        return function ()
            i = i + 1

            chash:simple_find(i)
        end, typ
    end
end

bench(10 * 1000, "chash new servers", resty_chash.new, nil, nil, servers)
bench(10 * 1000, "chash new2 servers", resty_chash.new2, nil, nil, servers)
bench(1 * 1000, "chash new servers2", resty_chash.new, nil, nil, servers2)
bench(1 * 1000, "chash new2 servers2", resty_chash.new2, nil, nil, servers2)
bench(10 * 1000, "new in func", gen_func(0))
bench(10 * 1000, "new dynamic", gen_func(1))
bench(10 * 1000, "up server3", gen_func(2))
bench(10 * 1000, "up server1", gen_func(3))
bench(10 * 1000, "down server1", gen_func(4))
bench(10 * 1000, "delete server3", gen_func(5))
bench(10 * 1000, "delete server1", gen_func(6))
bench(10 * 1000, "set server1 9", gen_func(7))
bench(10 * 1000, "set server1 8", gen_func(8))
bench(10 * 1000, "set server1 1", gen_func(9))

bench(1000 * 1000, "base for find", gen_func(100))
bench(1000 * 1000, "find", gen_func(101))
bench(1000 * 1000, "simple_find", gen_func(102))

---[=[
-- difference
local npoints = chash.npoints
local npoints2 = chash2.npoints
if npoints ~= npoints2 then
    error("not the same npoints")
end

local points = chash.points
local points2 = chash2.points

for i = 0, npoints - 1 do
    p1 = points[i]
    p2 = points2[i]

    if p1.hash ~= p2.hash then
        ngx.say("diff hash: ", p1.hash, " : ", p2.hash)
        --[[
    else
        ngx.say("same hash: ", p1.hash, " : ", p2.hash)
        --]]
    end

    if p1.id ~= p2.id then
        ngx.say("id: ", p1.id, " : ", p2.id)
    end
end
ngx.say("diff done\n")
--]=]

-- ngx.say("npoints: ", chash.npoints)
-- dump(chash)

--[[
run_find(chash)
run_simple_find(chash)

chash:up("server3")
run_find(chash)

-- dump(chash)

chash:up("server4")
run_find(chash)

chash:down("server4")
run_find(chash)

chash:down("server3")
run_find(chash)
run_simple_find(chash)
--]]

