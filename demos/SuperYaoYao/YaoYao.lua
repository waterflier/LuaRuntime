function YaoYaoNearUsers(username,key,x,y)
	--要登录用户才能摇，但这里为了简单先省略了验证key的过程
	
	local bizR = GetRuntimeFromGroup("SuperYaoYao.Biz")
	return bizR:call(function(name,gpsx,gpsy)
		local now = time()
		local r = GetCurrentRuntime()
		local usertable = r:GetRuntimeState("SuperYaoYao.UserPostion")
		usertable[name] = {x=gpsx,y=gpsy,updatetime=now}
		
		local bizRList = GetRuntimeListFromGroup("SuperYaoYao.Biz")
		local rlist = {}
		for i,v in pairs(bizRList) do
			--！！！逻辑上需要的是同时发起查询,但这里会强依赖bizRList里各个Runtime的顺序:必须等待上一个call返回结果了才会call下一个
			-- 所以这里需要asyn_call 。逻辑语义也是需要同时支持call,asyncall的
			result,ulist = v:call(function(cx,cy)
				local utable = GetCurrentRuntime():GetRuntimeState("SuperYaoYao.UserPostion")
				--Runtime状态的检索接口，这里用经典的select来表达逻辑意义。这里从优化性能的角度来说，需要根据查询条件建立更优化的索引，否则每次都要求所有的runtime有动作太慢了
				--这个遍历过程，也会包含自己，对GetCurrentRuntime():call 的调用，相当于投递了一次asyncall? 
				local users = utalbe:Select("select name where distance(cx,cy,x,y) < 10 and time()-updatetime < 10")
				return 0,users
			end,gpsx,gpsy)
			
			if result == 0 then
				rlist:append(ulist)
			end
		end
		
		return 0,rlist
	end,username,x,y)
end

function YaoYaoNearUsersUseAsynCall(username,key,x,y)
	local bizR = GetRuntimeFromGroup("SuperYaoYao.Biz")
	return bizR:call(function(name,gpsx,gpsy)
		local now = time()
		local r = GetCurrentRuntime()
		
		local usertable = r:GetRuntimeState("SuperYaoYao.UserPostion")
		usertable[name] = {x=gpsx,y=gpsy,updatetime=now}
		
		local bizRList = GetRuntimeListFromGroup("SuperYaoYao.Biz")
		local rlist = {}
		local total = #bizRList
		--在同一个函数中的任意位置调用GetCurrentCodeFrame()都会返回同一个对象
		local cf = GetCurrentCodeFrame()
		
		for i,v in pairs(bizRList) do
			result,ulist = v:asyncall(function(cx,cy)
				local utable = GetCurrentRuntime():GetRuntimeState("SuperYaoYao.UserPostion")
				--Runtime状态的检索接口，这里用经典的select来表达逻辑意义
				--这个遍历过程，也会包含自己，对GetCurrentRuntime():call 的调用，相当于投递了一次asyncall? 
				local users = utalbe:Select("select name where distance(cx,cy,x,y) < 10 and time()-updatetime < 10")
				return 0,users
			end,function (result,ulist)
				total = total - 1
				if result == 0 then
					rlist:append(ulist)
				end
				
				if total == 0 then
					--这里不能用GetCurrentCodeFrame():resume()
					--这里的codeframe已经与保存的code frame不同了
					cf:resume()
				end
			end,gpsx,gpsy)
		end
		
		--引入asyncall后，需要手工把codeframe置为休眠状态
		cf:yield()
		
		return 0,rlist
	end,username,x,y)
end