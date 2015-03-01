--红包状态保存在Hongbao.Storage


--实现红包逻辑
function Publish(username,key,amount,count)
	local hbBizR = GetRuntimeFromGroup("Hongbao.biz")
	local result,hbID = hbBizR:call(function(runtime,username,key,amount,count)	
		--验证username,key
		if UserInfo.CheckUserKey(username,key) ~= 0 then
			return 1,0
		end
		--创建红包，但不生效
		local hbCreatorR = GetRuntimeFromGroup("hbCreatorR")
		local ret,hbid = hbCreatorR:call(function(runtime,username,amount,count)
			--这里不用锁,本身的机制会保障在一个Runtime上执行操作的串行化
			--问题:SetRuntimeStorage是IO写操作，理论上可以引起CodeFrame Change
			hbid = runtime:GetRuntimeStorage("nextID")
			hbid ++ 
			runtime:SetRuntimeStorage("nextID",hbid)
			return 0,hbid
		end)
		
		if ret ~= 0 then
			return 2,0
		end
		
		hbStorageR = GetRuntimeFromGroup("Hongbao.Storage",hbid)
		ret,insertresult = hbStorageR:call(function(runtime,username,amount,count,hbid)
			local hbTable = runtime:GetRuntimeStorage("Hongbao.Info")
			ulist = {} -- 这里懒得写了，就是根据amount,count创建一个预分配的随机牌堆
			--以key-value的形式写入
			return hbTable:Insert(hbid,{isEnable=0,owner=username,ulist=ulist,nextpos=0})
		end,username,amount,count,hbid)
		
		if ret ~= 0 or insertresult ~= 0 then
			return 2,0
		end
		
		--扣除用户账户上的资金
		ret = BankAccount.Sub(username,amount,0)
		--扣除成功让红包生效
		if ret == 0 then
			ret = hbStorageR:call(function(runtime,hbid)
				local hbTable = runtime:GetRuntimeStorage("Hongbao.Info")
				return hbTable:Update("update isEnable=1 where hbid="..hbid)	
			end,hbid)
			return 0,hbid
		else
			return 3,0
		end
	end,username,key,amount,count)
	
	return result,hbID
end

--抢红包!先不做红包可抢用户组限制逻辑，假设知道了hbID就可以抢
--TODO 按下面的逻辑，如果一个hbID允许非常多的人来抢，这些人同时到来时，会由于设计问题顶不住（无法扩容）
function Fight(hbID,username,key)
	local hbBizR = GetRuntimeFromGroup("Hongbao.biz")
	
	local result,amount = hbBizR:call(function(runtime,hbID,username,key)
		--验证username,key
		if UserInfo.CheckUserKey(username,key) ~= 0 then
			return 1,0
		end

		--得到红包信息
		hbStorageR = GetRuntimeFromGroup("Hongbao.Storage",hbid)
		local result,isEnable,owner,ulist = hbStorageR:call(function(runtime,hbid)
			local hbTable = runtime:GetRuntimeStorage("Hongbao.Info")
			isEnable,owner,ulist = hbTable:Select("select isEnable,owner,ulist where hbid="..hbid)
			return isEnable,owner
		end,hbid)
		
		if result ~= 0 then
			return 1,0.0f
		end
		
		if not isEnable then
			return 3,0.0f
		end
		
		if username == owner then
			return 2,0.0f
		end
		
		if ulist:include(username) then
			return 2,0.0f
		end
		
		result,amount = hbStorageR:call(function(runtime,hbid,usrname)
			local hbTable = runtime:GetRuntimeStorage("Hongbao.Info")
			local result = 1
			local amount = 0
			--对红包上锁(如何进行分布式锁操作?) （如超时必须返回抢失败)
			--这里其实可以不要锁? 因为根据语义，下面的代码没有任何机会导致CodeFrame Change,所以肯定是不会被打断的
			local lockRet = LockHongbaoWrite(hbid,5) --超时时间为5
			if lockRet ~= 0 then
				return -1
			end
			
			isEnable,owner,ulist,nextpos = hbTable:Select("select isEnable,owner,ulist,nextpos where hbid="..hbid)
			
			--在红包的已领取信息中判断username是否领过
			if not ulist:include(username) and #ulist < nextpos then
				--在红包中添加一个领取记录
				ulist[nextpos].username = username
				amount = ulist[nextpos].amount
				nextpos++
				result = hbTable:Update("update ulist="..ulist..",nextpos="..nextpos.." where hbid="..hbid)
				--TODO:这里还需要通知Cache
			end
			
			--红包解锁
			UnlockHongbaoWrite(hbid)
			
			return result,amount
		end)
		
		--如果在这一步该bizRuntime挂掉，会出现红包已经领了但是用户的帐号没加钱的情况
		--根据领取结果添加用户账户上的资金 （添加失败的结果处理很麻烦..,放入重试队列?)
		BankAccount.Add(username,amount)
		
		return result,amount
	end,hbID,username,key)
	
	return result,amount
end

function GetInfo(hbID)
	local hbBizR = GetRuntimeFromGroup("Hongbao.biz")
	--读cache就可以了，上面逻辑简单实现，没有做Cache更新，所以这里也就先不实现了
end