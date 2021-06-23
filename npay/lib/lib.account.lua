--[[
    Lib.Account.lua
    
    Library for Account Management
    Auth: NoselessVillager/TrueDuck
]]--

local obj = require("lib.objects.lua")

local function generateUID()
    math.randomseed(os.time())
    local random = math.random
    local template ='MC00-NERD-4xxx-xxxx-xx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local account = {}

--[[ function account.Account:new()
    a or {}
    setmetatable(a, self)
    self.__index = self
    local account_id = generateUID()
    a.accountID = account_id
    return a
end
 ]]

function account.Account:get(v)
    checkArg(1, v, "string")

    if v == "accountOwner" then
        if self[v] then
            return self[v]
        else
            return "unoccupied"
        end
    elseif type(self[v]) != "function" then
        return self[v]
    elseif type(self[v]) == "function" then
        error("can't use Account:get() on method")
    else
        error("unknown error in Account:get()")
    end
end

function account.Account:set(k, v)
    checkArg(1, k, "string")
    checkArg(2, v, "string")

    self.k = v
end

function account.Account:setAccountOwner(v)
    checkArg(1, v, "table")
    
    if self:get("accountOwner") != "unoccupied" then
        return "already_occupied"
    elseif self:get("accountOwner") == "unoccupied" then
        self.accountOwner = v
    end

    return true
end

local accountClass = obj.createClass()

return accountClass