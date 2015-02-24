--demo应用，用户注册/更新信息/查找用户信息
--希望把“必须”关注的细节更突出，省略不该关注的细节
--减少“必须”关注的问题，用一种更直白但精确的方法来描述e-app的核心逻辑
--让一些本质复杂的问题能更好的通过SaaS的方法解决，其实就是定义更标准化的SaaS接口


function DoReg(name,pwd,info)
	local bizRuntime=GetRuntime("demo.biz")
	
	function bizReg(name,pwd,info)
		--有状态?
		local storageRuntime = GetRuntime("demo.storage."..ValueToKey(name))
		
		function storageReg(name,pwd,info)
			storage = GetCurrentRuntime().GetStorage()
			if storage["name"] ~= nil then
				log("user exist!")
				return 1
			end
			
			storage["name"] = {"pwd"=pwd,"info"=info}
			return 0
		end
		
		return storageRuntime.call(storageReg,name,pwd,info)
	end
	
	--bizRuntime不需要有startup sub,通过这种方式，一个sub被部署到bizRuntime上执行了
	result = bizRuntime.call(bizReg,name,pwd,info)
	resp = {}
	resp.result = result
	return resp
end
--在哪里运行？
function appMain()
	gate=GetModule("demo.gate")
	gate.addListener(function (package)
		if package.cmd == "demo.reg" then
			gate.sendresp(DoReg(package.name,package.pwd,package.info)))
		else if package.cmd == "demo.update" then
			--gate.sendresp(DoUpdate(package.name,package.info))
		else if package.cmd == "demo.query" then
			--gate.sendresp(DoQuery(package.name))
		end
	end)
end

--在root runtime中运行
function installApp()
	local interfaceRuntime=GetRuntime("demo.interface")
	local bizRuntime=GetRuntime("demo.biz")
	local storageRuntime=GetRuntime("demo.storage")
	
	--一个客户端的例子,通过输入一个类似于URL的东西来展开客户端逻辑
	createStartupLink("eapp://demo/update",function(runtime)
		print("please input your name")
		local username=io.read()
		print("please input your pwd")
		local pwd=io.read()
		print("login....")
		
		result = bizRuntime.call(bizReg,name,pwd,info)
		
		if result!=0 then
			print("login error!\n")
			return -1
		end
		
		print("login ok,please input your new info")
		local newinfo = io.read()
		result = bizRuntime.call(bizUpdate,name,info)
		
		
		--也可以使用传统协议法与服务器通信
		--gate=GetModule("demo.gate")
		--req = gate.createPackage("login")
		--tcpclient.send(req)
	end)
	
end
--[[
模块的全称是 应用名.模块，一个通用模块在不同的应用里，全局来看是不同的模块

几个事实
多个起始点的问题，e-app要在一个runtime上运行一个module,很多时候需要一个明确的“入口函数” 
（“针对客户端”来说，后台是否可以只通过客户端的runtime.call 或者 timer来驱动？而不需要一个明确的入口函数?

后台的各个Runtime之间，距离近的算并行计算问题，距离远的算分布式系统问题
客户端与客户端之间，算P2P问题？
一个App把自己的不同模块，智能的在不同的Runtime上运行，这个智能如何描述？
App如何 部署-发布-安装（被发现)

在同一个Runtime上运行两个App的问题？（Runtime上允许运行两个App么，如果Runtime只是个类似进程的黑盒，没这个必要） 两个App之间如何交互？

一个App的模块在Runtime上的生命周期问题？

开发者还是需要考虑如何把e-app划分成多个逻辑模块，并决定在哪些（哪个) Runtime上运行哪些Sub

分布式系统的几大经典问题
1.可并行问题 如何把逻辑拆成多个可并行的模块？完成并行设计后，如何简单的实现扩容（通过增加Runtime的方法来增强处理能力）
2.可用性问题 每个Runtime及其相关状态，都存在不稳定的。如何划分Runtime来减少这种不稳定对app带来的影响
3.一致性问题 
是否能在这个体系里减少，并更容易解决？

分布式系统通常会仔细考虑在压力升高后的取舍问题，比如牺牲一致性保证速度，牺牲某些功能保证关键功能等，这些决策有哪些能自动做？不能自动做的如何在系统里清楚的描述
负载均和问题（设计负载与实际负载不符合），如何解决


对分布式系统的基础设施（网络），提出新的要求
1.节点，节点与节点之间建立联系，数据在节点之间的传输
2.系统各个节点的逻辑拓扑与物理拓扑



]]--
