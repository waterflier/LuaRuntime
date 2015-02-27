--在另一个随身设备上运行

--关键逻辑
-- 启动授权，从一个UserInfoClient.lua里获得已经登录的信息 （需要修改UserInfoClient?)
-- 得到一个靠近的Runtime,并且其也运行了同样的模块
-- 与之交换信息，得到对方登录的用户名
-- 再次靠近PC时，在PC上弹出所有收集到的用户名
function WatchMain()
	wr = GetCurrentRuntime()
	wr.GetEvent("device-near"):Attach(function(thisRuntime,otherRutnime,distance)
		if otherRuntime:isTrusted(thisRuntime) then
			if otherRuntime:DeviceIs("pc") then
				userlist = thisRuntime:GetStorage():getValue("/userinfo/tracker")
				otherRuntime:call(function (meetusers)
					--跨runtime创建UI 
					tipswnd = CreateTipsWnd()
					tipswnd:setlist(userlist)
					tipswnd:show()
				end,userlist)
				
				thisRuntime:GetStorage():setValue("/userinfo/tracker",{}) --清零了，等着下次出门
			end
		else
			--！！！ 待定：这里不需要OtherRutnime授权? 只需要大家都有这个应用就行？
			userstate = otherRuntime.try_call("GetClientState")
			if userstate then		
				username = userstate["username"]
				thisRuntime:GetStorage():getValue("/userinfo/tracker"):append(username)
			end
		end
	end)
	return 0
end

--为整个e-app Enable 可穿戴设备的功能,这个函数实现在哪个模块？。。。
function EnableUserInfoWatch()
	clientRG = GetRuntimeGroup("userinfo.client")
	clientRG.GetEvent("device-near"):Attach(function(clientRuntime,otherRuntime,distance)
		if distance < 2 then --Runtime之间的距离，目前简单的定义为绝对距离 米
			if otherRuntime:DeviceIs("watch") then --otherRuntime的类型是 手表
				if clientRuntime:trust(otherRuntime) then --互相信任
					otherRuntime:call(WatchMain)
				end
			end
		end
	end)
end

