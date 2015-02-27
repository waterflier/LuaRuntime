#Runtime

可以使用一个字符串来表示Runtime的物理地址,这个字符串的含义由Runtime的实现者定义
拿到一个Runtime对象后，可以获取其属性
runtime的sandbox属性可以在任意代码里读取
runtime的非sandbox属性只可以在runtime里运行的code frame里获取


Runtime的状态分为 未启动->启动中->等待->运行->关闭中
等待状态的Runtime没有运行任何CodeFrame，运行状态的Runtime正在运行一个确定的Code Frame

Code Frame最终会被结束，也可以中途被挂起。
一个结束的CodeFrame会导致该CodeFrame的销毁
当一个Runtiime上的所有CodeFrame都处于挂起状态，或不包含任何CodeFrame时，该Runtime处于等待状态
一个codeframe必须尽快进入挂起/结束，任何codeframe都不能一次执行过长的时间

Runtime有以下几种情况能从等待状态变为运行状态
1.一个订阅的事件触发了，会运行该事件的一个响应代码
2.用户要求Runtime打开一个startupLink,Runtime会尝试运行startLink对应的Sub
3.别的Runtime投递一个Sub到该Runtime运行
4.CodeFrame从挂起状态变为就绪状态（这个操作通常都是由 驱动模块 搞定)

#Event
Event分为驱动事件与用户自定义事件
当Event发生时，Runtime会把Event的处理函数封装成一个CodeFrame，放入Runtime的待执行队列

让Runtime加载新的驱动，可以增加新的驱动事件。驱动事件的边界通常只局限在一个Runtime内
让Runtime加载模块，可以增加新的用户自定义事件。用户自定义事件的边界可以是整个App范围

#Sub 
result,function,subresults = Runtime.call(sub,args...)  --待定
从语义来看,sub就是一个function。但实际上，其灵活度是受到限制的：其访问upvalue只能通过值的方式只读访问.（这里会有隐含的同步问题）
在sub的代码中，可以使用GetCurrentRuntime()获得当前的Runtime，通过GetCallerRuntime()获得投递Sub的源Runtime
Runtimie.call的返回值，前两个是固定的。 result表示本次操作的结果，如果值不为0，可以明白调用失败的原因。function表示sub的完成操作在CallerRuntime中运行






