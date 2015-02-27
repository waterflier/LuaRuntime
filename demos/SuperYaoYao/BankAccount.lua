--

function GetAccountInfo(username)
end

function Add(username,willAdd)

end

function Sub(username,willRemove)

end

--注意：这里选择提供trans接口，或由模块的使用者调用Add,Sub来实现转账的设计抉择
--      取决于实现事务的便利性
function Trans(formuser,touser,amount)
end