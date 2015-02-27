--该文件确定如何使用已经开发完成的模块来组装app

--安装/部署App,很有趣的是，这个函数不是entri-app的组成部分
function installApp()
	--app的信息要保存在一个app-meta 服务器上，这相当于单机可执行文件的导入表
	--app-meta server,应基于LuaRuntime开发，如诺不能，也没关系
	app = RegisterApp("com.demo.userinfo","1.0.0.1") 
	
	--app由哪些模块构成?
	app:UseModule("UserInfo")
	app:UseModule("UserInfoclient")
	app:UseModule("UserInfoWatch")
	
	--一个Runtime打开startup link的逻辑是什么?
	clientGP = app:AddRuntimeGroup("userinfo.client")
	app:CreateStartupLink("eapp://demo.userinfo/pcclient",UserInfoClient.main,clientGP)
	
	--这里调用应该是不对的
	EnableUserInfoWatch()
	
	--配置app的Runtime (关键步骤?) 明确RuntimeGroup,Runtime,Device之间的关系?
	--clientRuntime 任意一个打开了startupLink的Runtime
	--UserInfoBizRutnime
	bizGP = app:AddRuntimeGroup("userinfo.biz")
	--配置一个RuntimeGroup的一些重要的函数，这些函数会在各个Runtime里执行
	--RuntimeGroup的信息保存在哪里？保存在App的配置信息里？App的配置信息最终保存在哪里？
	bizGP:Config({
		Selector=function(self)
		end,
		
		OnAddRuntime=function(self)
		end,
		
		OnRuntimeError=function(self)
		end,
		
		OnRuntimeRemove=function(self)
		end,
		
		OnGroupLoadChanged=function(self)
		end
		
	})
	--为RuntimeGroup添加一些初始的Runtime, 
	--由于有的Runtime要持有状态，这里必然不会那么简单。
	--但可以硬性要求：Runtime是可以在Device之间迁移的
	--这么看起来Runtime目前最好的一个实现就是基于Docker了
	bizGP:AddRuntime(...)
	bizGP:AddRuntime(...)
	
	--该RuntimeGroup里的每个Runtime都持有了关键的，各不相同的状态
	--对于所有的分布式系统来说，如何处理这些状态都是非常关键的问题
	--1.状态的可靠性问题，要提高可靠性，需要让同一个状态被更多的Runtime持有(Runtime可能损坏)
	--2.状态的一致性问题，当一个状态被多个Runtime持有后，这个状态就会有一致性问题. 要完美的解决1.2之间的矛盾，目前最好的方法是paxos?
	--3.状态迁移的问题，当需要调整一个RuntimeGroup持有的状态，具体分配到哪些Runtime上时
	-- 以上3个典型问题，本身就是App中的关键逻辑（几乎无法自动完成?),需要更清晰的在模块实现中展现。而不是放在这个不属于任何模块的配置函数里
	app:AddRuntimeGroup("userinfo.cache")
	--UserInfoStorageRuntime
	app:AddRuntimeGroup("userinfo.storage")
	
end

--开始/停止应用程序
function EnableApp(isEnable)

end
