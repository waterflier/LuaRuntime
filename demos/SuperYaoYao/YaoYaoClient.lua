function main(runtime,args)
	--虽然复用了UserInfo的M层 模块，但是否需要服用UserInfoClient的登录逻辑
	local username,key
	runtime:GetEvent("UserStateChange"):Attach(function(username,isLogin)
		print("等待摇一摇:")
		runtime:GetEvent("device-shake"):Attach(function(thisRuntime,otherRutnime,distance)
			local x,y = runtime:GetDevice("gps"):GetPos()
			local result,userlist = YaoYao.YaoYaoNearUsersUseAsynCall(username,key,x,y)
			if result == 0 then
				print("这些用户和你一起摇:"..userlist)
			end
		end)
	end)
end