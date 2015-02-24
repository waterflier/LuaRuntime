--该文件确定如何使用已经开发完成的模块来组装app

--安装/部署App
function installApp()
	--app的信息要保存在一个app-meta 服务器上，这相当于单机可执行文件的导入表
	app = RegisterApp("com.demo.userinfo") 
	
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
	
	--UserInfoCacheRutime
	app:AddRuntimeGroup("userinfo.cache")
	--UserInfoStorageRuntime
	app:AddRuntimeGroup("userinfo.storage")
	
end
