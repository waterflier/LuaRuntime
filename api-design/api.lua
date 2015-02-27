--*****模块api  
--特点：可以用类似yum install的方法在runtime里安装模块
-- 关注模块的依赖关系，可以在安装模块的时候自动安装依赖模块
-- 标准化的，基于签名的模块验证机制

--使用模块
module = Env.LoadModule() -- 防止Dll hell的环境机制，允许同一个模块的多个版本,所以需要通过Env来约束,Env本质上是一个ClassLoader
module.foo() --使用module


--创建模块
--一个模块通常等价于一个文件夹，内有多个程序文件


--查询模块

--C 驱动模块(暂时不管)

--***RuntimeGroup API

--*****Runtime API
--得到Runtime

--创建Runtime

--得到/修改Runtime的状态

--创建 Sub 

--得到Sub信息

--在Runtime上运行Sub

--*****Event API
--定义Event

--使用Event

--EventLoop

--CodeFrame （由于EventLoop的存在,代码都是运行在code frame中的，所以.. code frame必须返回)

--Runtime支持的标准Event

--***** Piple API





