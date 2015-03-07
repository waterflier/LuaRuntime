--安装MVC的方式分层，这里就是M层
function Register(name,pwd,info)
	local bizR = GetRuntime("userinfo.biz")
	bizR.Register()
	
	bizR.call(Module.CreateSub(function(name,pwd,info)
	
	end),name,pwd,info)
	
	--encode function->send to server->decode function->is in known list
	result = bizR.call(function(name,pwd,info)
		--从一个RuntimeGroup中选择一个Runtime
		local cacheR = GetRuntime("userinfo.cache")
		local isCacheHit = cacheR.call(function(name)
			usercache = cacheR.GetGlobal("Cache.UserInfo")
			if usercache[name] then
				return true
			else
				return false
		end,name)
		
		if isCacheHit then
			return 1 --注册失败
		end
		
		local storageR = GetRuntime("userinfo.storage")
		return storageR.call(function(name,pwd,info)
			s = storageR.GetStorage()
			
			if s.setValue("/userinfo/"..name,{pwd=pwd,info=info}) == 0 then
				return 0
			end
			
			return 1
		end,name,pwd,info)
	end,name,pwd,info)
	
	return result
end

function Login(name,pwd)
	local bizR = GetRuntime("userinfo.biz")
	local clientR = GetCurrentRuntime() 
	result = bizR.call(function(name,pwd)
		local clientRInfoTable = bizR.GetGlobal("clientR")
		local clientRInfo = clientRInfoTable[clientR]
		if clientRInfo ~= nil then
			if time(0) - clientRInfo.lastLoginTime < 1 then
				return 1
			end
			clientRInfo.lastLogintime = time(0)
		else
			clientRInfo[clientR] = {lastLoginTime=time(0)}
		end
		
		local cacheR = GetRutnime("userinfo.cache")
		local info = cacheR.call(function(name)
			usercache = cacheR.GetGlobal("Cache.UserInfo")
			return usercache[name]
		end,name)
		
		if info == nil then
			local storageR = GetRuntime("userinfo.storage")
			info = storageR.call(function(name,pwd,info)
				s = storageR.GetStorage()
				
				return s.getValue("/userinfo/"..name)
			end,name,pwd,info)
		else

		if info then	
			if info.pwd == pwd then
				--生成可用的key
				key = CreateKey(name,clientR)
				return 0
			else
				return 1
			end
		end
		
		return 2 --用户不存在
	end,name,pwd)
	
	GetCurrentRuntime():SetRuntimeState("UserInfo.Client.State",{login=true,username=name,key=key})
	return result,key
end

function UpdateInfo(name,info,key)
	local bizR = GetRuntime("userinfo.biz")
	local clientR = GetCurrentRuntime() 
	return bizR.call(function(name,info,key)
		savedKey = GetKey(name,clientR)
		if key == savedKey then
			local storageR = GetRuntime("userinfo.storage")
			local result = storageR.call(function(name,pwd,info)
				s = storageR.GetStorage()
				
				return s.setValue("/userinfo/"..name,{info=info}) --可能需要触发事件?
			end,name,pwd,info)
			
			return result
		end
		
		return 1
	end,name,info,key)
end

function Query(name)
	local bizR = GetRuntime("userinfo.biz")
	return bizR.call(function(name)
		local cacheR = GetRutnime("userinfo.cache")
		local info = cacheR.call(function(name)
			usercache = cacheR.GetGlobal("Cache.UserInfo")
			return usercache[name]
		end,name)
		
		if info then
			return info
		end
		
		local storageR = GetRuntime("userinfo.storage")
		info = storageR.call(function(name)
			local s = storageR.GetStorage()
			return s.getValue("/userinfo/"..name)
		end)
		
		if info then
			cacheR.call(function(name,info)
				usercache = cacheR.GetGlobal("Cache.UserInfo")
				usercache[name].info = info
			end,name)
		
			return info
		end
		
		return nil
	end,name)
end

function StartCleanUpTimer()
	--在所有的Runtime上运行?
	local bizRG = GetRuntimeGroup("userinfo.biz")
	local cacheRG = GetRuntimeGroup("userinfo.cache")
	bizRG:AddTimer(5,function(self)
		CleanUnusedKey()
		CleanClientRInfoTable()
	end)
	
	cacheRG:AddTimer(5,function(self)
		CleanCache()
	end
end

module("UserInfo") = {
	Register=Register,
	Login=Login,
	UpdateInfo=UpdateInfo,
	Query=Query
}

