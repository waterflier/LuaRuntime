--ADClient运行在广告牌上。有两种启动方法
--一种是广告牌启动后打开一个Startlink,则会启动main函数
--另一种把广告牌设备当作“后台设备”来看，这时可以由App里的其它Runtiime来Push一个Sub

local hbList = {}
local adList = {}

function main(runtime,args)
	print("startup... ")
	runtime:AddTimer(10,function()
		UpdateADWnd(adList)
	end)
	
end