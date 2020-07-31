local _M = {}

_M.name = "balancer-utils"
_M.version = "0.03"

local new_tab
do
    local ok
    ok, new_tab = pcall(require, "table.new")
    if not ok or type(new_tab) ~= "function" then
        new_tab = function (narr, nrec) return {} end
    end
end

_M.new_tab = new_tab

local copy
do
    local ok
    ok, copy = pcall(require, "table.clone")
    if not ok or type(copy) ~= "function" then
        copy = function(nodes)
            local newnodes = new_tab(0, 0)
            for id, weight in pairs(nodes) do
                newnodes[id] = weight
            end

            return newnodes
        end
    end
end
_M.copy = copy

local nkeys
do
    local ok
    ok, nkeys = pcall(require, "table.nkeys")
    if not ok or type(nkeys) ~= "function" then
        nkeys = function(tab)
            local count = 0
            for _, _ in pairs(tab) do
                count = count + 1
            end
            return count
        end
    end
end

_M.nkeys = nkeys

return _M
