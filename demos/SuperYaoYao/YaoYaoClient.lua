function main(runtime,args)
	--虽然复用了UserInfo的M层 模块，但是否需要服用UserInfoClient的登录逻辑
	local username,key
	
	
	--检测摇一摇事件
	runtime:GetEvent("UserStateChange"):Attach(function(username,isLogin)
		--发红包逻辑 新的语义对于 分层方法提出了新的挑战
		function pubHongbao(amount,count,adinfo)
			if amount > 0 and count > 0 then
				local myamount = BankAccount.GetAccountInfo(username,key)
				if myamount < amount then
					print("你的钱不够")
					return -1
				end
				
				local ret,hbid = Hongbao.Publish(username,key,amount,count)
				if ret == 0 then
					return ret,hbid
				end
				
				return ret
			end
			
			return -1
		end
	
		print("等待摇一摇:")
		--检测是否有靠近广告牌
		local nearADRuntime = nil
		runtime.GetEvent("device-near"):Attach(function(thisRuntime,otherRuntime,distance)
			if distance < 5 and IsGroupOf(otherRuntime,"YaoYao.ADClient") then
				print("附近有红包广告牌!，摇一摇可以得到红包! 也可以发红包!")
				--这里只做了靠近逻辑，没做离开逻辑(device-near事件的语义不是很清晰)
				nearADRuntime = otherRuntime
			end
		end)
	
		runtime:GetEvent("device-shake"):Attach(function(thisRuntime,otherRutnime,distance)
			--互斥逻辑一定要修改原有逻辑，而不能简单的多Attach一次Event
			
			if nearADRuntime then
				--摇红包，这种写法依赖 客户端能与广告牌建立连接
				-- 另一种写法是用老的逻辑，但是要求服务器除了根据当前坐标返回一组用户外，还可以返回一个hbID
				local result,hbInfo = nearADRuntimie:call(function(name)
					local hbList = GetRuntimeState(GetCurrentRuntime(),"ADClient.HongbaoList")
					local hbInfo = hbList[0]
					if hbInfo then
						return 0,hbInfo
					end
					
					return 1,nil
				end,username)
				
				if hbInfo then
					print("发现"..hbInfo.username.."发放的红包!")
					result,amount = Hongbao.Fight(hbInfo.hbID,username,key)
					if result == 0 then
						--于此同时 广告牌也可以有显示(多个用户一起抢的时候，广告牌的显示资源冲突如何解决)
						
						print("抢到红包 "..amount.." 元!")
						amount = BankAccount.GetAccountInfo(username,key)
						print("钱包里还有 "..amount.." 元!")
						
						print(hbInfo.ADInfo)
						
						print("--------------------------")
						hbUserInfo = Hongbao.GetInfo(hbInfo.hbID)
						for k,v in pairs(hbUserInfo) do
							print(k.." 抢到了 "..v.." 元")
						end
					end
					
					
				end
				
			else
				--摇用户
				local x,y = runtime:GetDevice("gps"):GetPos()
				local result,userlist = YaoYao.YaoYaoNearUsersUseAsynCall(username,key,x,y)
				if result == 0 then
					print("这些用户和你一起摇:"..userlist)
				end
			end
		end)
		
		runtime:GetEvent("device")
	end)
end

