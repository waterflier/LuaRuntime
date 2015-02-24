--MVC分层，这里是界面层
--为了简单的用于演示，这里用控制台作为界面

require("UserInfo")
require("io")

--属于UserInfoClient模块的事件
CreateEvent("UserStateChange") --这个事件应该放到UserInfo 模块里

function GetClientState()
	return {state=GetCurrentRuntime():GetRuntimeState("userstate"),username=GetCurrentRuntime():GetRuntimeState("username")}
end

function main(runtime,args)
	print("please input your name:")
	local username=io.read(stdin) --整个函数是个传统意义上的block io. 在新的设计里，这里并不会真的堵塞，而是导致了一次协程调度。 （io库要实现过)
	print("please input your pwd:")
	local pwd=io.read(stdin)
	print("login....")
	
	local key = ""
	result,key = UserInfo.Login(username,pwd) --这个函数必然是异步的，这里默认是使用协程的方式来处理的。这个函数调用前，和调用后会处在不同的code frame中
	GetCurrentRuntime():SetRuntimeState("username",username)
	GetCurrentRuntime():SetRuntimeState("key",key)
	if result~=0 then
		print("login error!\n")
		return -1
	end
	GetCurrentRuntime():SetRuntimeState("userstate","login")
	GetEvent("UserStateChange"):Fire("UserStateChange","login")
	
	print("login ok,please input your new info:")
	local newinfo = io.read(stdin)
	result = UserInfo.UpdateInfo(username,newinfo,key)
	if result ~= then 
		print("update userinfo error.\n")
		return -1
	end

	print("Update userinfo success!\n")
	
	return 0
end

