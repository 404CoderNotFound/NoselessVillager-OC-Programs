local modemport = 588

--[[ Server-sided account handler ]]--

local component = require("component")
local gpu = component.gpu
local event = require("event")
local ser = require("serialization")
local modem = component.modem 
writer = component.os_cardwriter
data = component.data

local cardStatusLabel, accountList, accountLabelText
local cardBlockButtun, 

local function saveTable(tbl, label, ecPrivate, iv)
	if not iv or not tbl or not label or not ecPrivate then
		return "missing_argument"
	end
	local serializedTable = serialization.serialize(tbl)
	
	local encryptedTbl = data.encrypt(serializedTable, ecPrivate, iv)
	
	-- open table file
	local tableFile = assert(io.open("sctbl", "r"))
	
	-- read table file
	local raw_stbl = tableFile:read("*a")
	local sctbl = serialization.unserialize(raw_stbl)
	
	-- table file is no longer needed and needs to be cleared
	tableFile:close()
	
	-- append new secured account to table
	sctbl[label] = {encryptedTbl, data.sha256(serialization.serialize(ecPrivate)), iv}
	
	-- re-open cleared table file
	clearedTableFile = assert(io.open("sctbl", "w+"))
	
	-- write new secure table to file
	clearedTableFile:write(serialization.serialize(sctbl))
	clearedTableFile:close()
	
	return 0
end

function setContains(set, key)
    return set[key] ~= nil
end

local function loadTable(label, psw)
	-- open table file
	local tableFile = assert(io.open("sctbl", "r"))
	
	-- read raw table file
	raw_stbl = tableFile:read("*a")
	tableFile:close()
	-- deserialize table
	csctbl = serialization.unserialize(raw_stbl)
	
	if setContains(csctbl, label) == true then else return 1 end
	
	-- get hashed decryption key
	local hashed_prkey = serialization.unserialize(csctbl[label][2])
	
	if data.sha256(psw) == hashed_prkey then
		local eact = csctbl[label][1]
		local iv = csctbl[label][3]
		local dact = data.decrypt(eact, psw, iv)
		local ulact = serialization.unserialize(dact)
		return ulact
	else
		return "invalid_pwd"
	end
end

local function newKeyPair()
	local pub, priv = data.generateKeyPair(256)
	local iv = data.random(16)
	return pub, priv, iv
end

local function validateTransaction(transFrom, transTo, cardHash, keyFrom, keyTo)
	local transFromTable = loadTable(transFrom, keyFrom)
	local transToTable = loadTable(transTo, keyTo)
	
	if transFromTable ~= "invalid_pwd" and transFromTable ~= 1 and transToTable ~= "invalid_pwd" and transToTable ~= 1 then else return 1 end
	if transToTable["cardHash"] = cardHash then else return "invalid_cardhash" end
	
	return true
end

local function main()
	local memory = {}
	local stream = minitel.listen(modemport)
	while true do
		local recv = serialization.unserialize(stream:read())
		local decryptedrecv
		local transactionSuccess
		if recv ~= "new_key_pair\n" then
			decryptedrecv = data.decrypt(recv, memory["keyInfo"][2], memory["keyInfo"][3])
		end
		if recv == "new_key_pair\n" then
			local pub, priv, iv = newKeyPair()
			stream:write(serialization.serialize({pub, iv}) .. "\n")
			memory["keyInfo"] = {pub, priv, iv}
		elseif string.sub(decryptedrecv, 1, 10) == "trans_from" then
			memory["transFrom"] = string.sub(decryptedrecv, 12, (string.len(decryptedrecv) - 2))
		elseif string.sub(decryptedrecv, 1, 8) == "trans_to" then
			memory["transTo"] = string.sub(decryptedrecv, 10, (string.len(decryptedrecv) - 2))
		elseif string.sub(decryptedrecv, 1, 9) == "card_hash" then
			memory["cardInfo"] = {"cardHash" = string.sub(decryptedrecv, 11, (string.len(decryptedrecv) - 2))}
		elseif string.sub(decryptedrecv, 1, 9) == "card_priv" then
			memory["cardInfo"] = {"cardPvk" = string.sub(decryptedrecv, 11, (string.len(decryptedrecv) - 2))}
		elseif string.sub(decryptedrecv, 1, 6) == "to_pvk" then
			memory["toPvk"] = string.sub(decryptedrecv, 8, (string.len(decryptedrecv) - 2))
		elseif string.sub(decryptedrecv, 1, 10) == "start_trans" then
			if validateTransaction(memory["transFrom"], memory["transTo"], memory["cardInfo"]["cardHash"], memory["toPvk"], memory["cardInfo"]["cardPvk"]) == true then
			 transactionSuccess = 1
			 --[[ transaction code ]]--
			else
			 transactionSuccess = 0
			end
		end
		
		if transactionSuccess == 1 then
			stream:write(serialization.serialize("transaction_success\n"))
			break
		elseif transactionSuccess == 0 then
			stream:write(serialization.serialize("transaction_failed\n"))
			break
		end
		os.sleep(0.001)
	end
	memory = {}
	stream:close()
end

