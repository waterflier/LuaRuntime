--钱包模块，简单的记录了每个用户的账户余额信息，并尝试提供了支持事务的接口（两段提交?)
--这个模块实现起来并不容易 (暂时先不实现事务,反正目前SuperYaoYao用不到)

--只是简单的查询一下帐号信息，通过cache就好了
function GetAccountInfo(username,tid)
	local bizRuntime = GetRuntimeFromGruop("BankAccount.Biz")
	local result,info = bizRuntimie:call(function(runtime,username)
		cacheR = GetRuntimeFromGroup("BankAccount.Cache",username)
		return cacheR:call(function(runtime,username)
			local accountTable = runtime:GetRuntimeState("AccountInfo")
			return 0,accountTable[username] 
		end,username)
	end,username)
	
	if result ~= 0 or info == nil then
		--不管什么原因查询cache失败，都直接读存储
		--这种策略在某些极端情况下可能会出问题
		storageR = GetRuntimeFromGroup("BankAccount.Storage",username)
		local result,info = storageR:call(function(runtime,username)
			local accountTable = runtime:GetRuntimeStorage("AccountInfo")
			return 0,accountTable[username] 
		end
		
		if result == 0 and info ~= nil then
			cacheR:call(function(runtime,username,info)
				local accountTable = runtime:GetRuntimeState("AccountInfo")
				accountTable[username] = info
			end,username,info)
		end
	end
	
	return result,info
end

function Add(username,willAdd,tid)
	local bizRuntime = GetRuntimeFromGruop("BankAccount.Biz")
	
	local result = bizRuntime:call(function(runtime,username,willAdd,tid)
		local bizStorage = runtime:GetRuntimeStorage("AccountLog")
		bizStorage:append({stamp=time(),username=username,action="add",amount=willAdd,tid=tid})
		
		storageR = GetRuntimeFromGroup("BankAccount.Storage",username)
		accountLogR = GetRuntimeFromGroup("BankAccount.Logger",username)
		accountLogR:call(function(runtime,username,willAdd,tid)
			storage = runtime:GetRuntimeStorage("AccountLog")
			storage:append({stamp=time(),username=username,action="add",amount=willAdd,tid=tid})
		end,username,willAdd,tid)
		
		local result,info = storageR:call(function(runtime,username)
			local accountTable = runtime:GetRuntimeStorage("AccountInfo")
			local info = accountTable[username]
			if info then
				local upresult = accountTable:Update("update amount="..info.amount+willAdd.." where username="..username)
			end
			return 0,accountTable[username] 
		end
		
		if result == 0 then
			accountLogR:call(function(runtime,username,willAdd,tid)
				storage = runtime:GetRuntimeStorage("AccountLog")
				storage:append({stamp=time(),username=username,action="commit-add",amount=willAdd,tid=tid})
			end,username,willAdd,tid)
			
			--todo:还要更新cache
		end
		
		return result
	end,username,willAdd,tid)
	
	return result
	
end

function Sub(username,willRemove,tid)
	local bizRuntime = GetRuntimeFromGruop("BankAccount.Biz")
	
	local result = bizRuntime:call(function(runtime,username,willRemove,tid)
		local bizStorage = runtime:GetRuntimeStorage("AccountLog")
		bizStorage:append({stamp=time(),username=username,action="sub",amount=willRemove,tid=tid})
		
		storageR = GetRuntimeFromGroup("BankAccount.Storage",username)
		accountLogR = GetRuntimeFromGroup("BankAccount.Logger",username)
		accountLogR:call(function(runtime,username,willRemove,tid)
			storage = runtime:GetRuntimeStorage("AccountLog")
			storage:append({stamp=time(),username=username,action="add",amount=willRemove,tid=tid})
		end,username,willRemove,tid)
		
		local result,info = storageR:call(function(runtime,username)
			local accountTable = runtime:GetRuntimeStorage("AccountInfo")
			local info = accountTable[username]
			if info then
				if info.amount < willRemove then
					return 1 --没有余额了
				end
				
				local upresult = accountTable:Update("update amount="..info.amount-willRemove.." where username="..username)
			end
			return 0,accountTable[username] 
		end
		
		if result == 0 then
			accountLogR:call(function(runtime,username,willRemove,tid)
				storage = runtime:GetRuntimeStorage("AccountLog")
				storage:append({stamp=time(),username=username,action="commit-sub",amount=willRemove,tid=tid})
			end,username,willRemove,tid)
			
			--todo:还要更新cache
		end
		
		return result
	end,username,willRemove,tid)
	
	return result

end

------------------------------------------------------------------------------------------
function CreateTransaction()
end

function CommitTransaction()
end
--注意：这里选择提供trans接口，或由模块的使用者调用Add,Sub来实现转账的设计抉择
--      取决于实现事务的便利性
function Trans(formuser,touser,amount)
end