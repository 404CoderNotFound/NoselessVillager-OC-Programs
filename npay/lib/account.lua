--[[
    lib.account
    
    library for Account Management
    auth: NoselessVillager/TrueDuck
]]--

local obj = require("objects")

local function generateUID()
    math.randomseed(os.time())
    local random = math.random
    local template ='yyxx-yyyy-xxxx-xxxx-xxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local Account = obj.newClass("Account")

--[[ function Account:new()
    a = a or {}
    setmetatable(a, self)
    self.__index = self
    local account_id = generateUID()
    a.accountID = account_id
    return a
end ]]


function Account:get(v)
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

function Account:set(k, v)
    checkArg(1, k, "string")
    checkArg(2, v, "string")

    self.k = v
end

function Account:setAccountOwner(v)
    checkArg(1, v, "string")
    
    if self:get("accountOwner") != "unoccupied" then
        return "already_occupied"
    elseif self:get("accountOwner") == "unoccupied" then
        self.accountOwner = v
    end

    return true
end

local FrozenAccount = newClass("FrozenAccount", Account)

function Account:freeze()
    Atype = self.type
    frozenAccount = FrozenAccount:cast(self)
end

FrozenAccount["set"] = function(...) print("Cannot set() on a frozen account.") end
FrozenAccount["setAccountOwner"] = function(...) print("Cannot setAccountOwner() on a frozen account.") end

function FrozenAccount:unfreeze()
    local unfrozenAccount = Atype:cast(self)
    return unfrozenAccount
end

return Account, FrozenAccount