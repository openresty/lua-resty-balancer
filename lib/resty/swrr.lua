local pairs = pairs
local next = next
local tonumber = tonumber
local setmetatable = setmetatable
local math_random = math.random
local error = error

local utils = require "resty.balancer.utils"

local copy = utils.copy
local nkeys = utils.nkeys
local new_tab = utils.new_tab

local _M = {}
local mt = { __index = _M }


local function new_current_weights(nodes)
    local current_weights = new_tab(0, nkeys(nodes))
    for id, _ in pairs(nodes) do
        current_weights[id] = 0
    end
    return current_weights
end


local function random_start(self)
    local count = nkeys(self.nodes)
    local random_times = math_random(count)

    for _ = 1, random_times do
        self:next()
    end
end


function _M.new(_, nodes)
    local newnodes = copy(nodes)
    local current_weights = new_current_weights(nodes)

    local self = {
        nodes = newnodes,  -- it's safer to copy one
        current_weights = current_weights,
    }
    self = setmetatable(self, mt)
    random_start(self)
    return self
end


function _M.reinit(self, nodes)
    local newnodes = copy(nodes)
    local current_weights = new_current_weights(newnodes)

    self.nodes = newnodes
    self.current_weights = current_weights
    random_start(self)
end


local function _delete(self, id)
    local nodes = self.nodes
    local current_weights = self.current_weights

    nodes[id] = nil
    current_weights[id] = nil
end
_M.delete = _delete


local function _decr(self, id, weight)
    local weight = tonumber(weight) or 1
    local nodes = self.nodes

    local old_weight = nodes[id]

    if not old_weight then
        return
    end

    if old_weight <= weight then
        return _delete(self, id)
    end

    nodes[id] = old_weight - weight
end
_M.decr = _decr


local function _incr(self, id, weight)
    local weight = tonumber(weight) or 1
    local nodes = self.nodes

    nodes[id] = (nodes[id] or 0) + weight
end
_M.incr = _incr


function _M.set(self, id, new_weight)
    local new_weight = tonumber(new_weight) or 0
    local old_weight = self.nodes[id] or 0

    if old_weight == new_weight then
        return
    end

    if old_weight < new_weight then
        return _incr(self, id, new_weight - old_weight)
    end

    return _decr(self, id, old_weight - new_weight)
end


local function find(self)
    local nodes = self.nodes
    local current_weights = self.current_weights

    local best_id = nil
    local best_current_weight = 0
    local total = 0

    for id, weight in pairs(nodes) do
        local current_weight = current_weights[id]
        total = total + weight
        current_weight = current_weight + weight
        current_weights[id] = current_weight

        if best_id == nil or best_current_weight < current_weight then
            best_id = id
            best_current_weight = current_weight
        end
    end

    if best_id ~= nil then
        current_weights[best_id] = best_current_weight - total
    end

    return best_id
end
_M.find = find
_M.next = find


return _M
