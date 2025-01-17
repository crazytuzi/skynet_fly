
local skynet = require "skynet"
local contriner_client = require "contriner_client"

local setmetatable = setmetatable
local assert = assert
local type = type

contriner_client:register("cluster_client_m")

local M = {}
local meta = {__index = M}
local cluster_client = nil

local g_instance_map = {}

--[[
	函数作用域：M 的成员函数
	函数名称: new
	描述:创建一个skynet远程rpc调用对象
	参数:
		- svr_name (string): 结点名称
		- instance_name (string): 对端模板名称
]]
function M:new(svr_name,module_name,instance_name)
	assert(svr_name,"not svr_name")
	assert(module_name,"not module_name")
	local t = {
		svr_name = svr_name,
		module_name = module_name,
		instance_name = instance_name,
	}

	if not cluster_client then
		cluster_client = contriner_client:new("cluster_client_m")
	end

	setmetatable(t,meta)

	return t
end

--有时候并不想创建实例
function M:instance(svr_name,module_name,instance_name)
	assert(svr_name,"not svr_name")
	assert(module_name,"not module_name")

	if not g_instance_map[svr_name] then
		g_instance_map[svr_name] = {}
	end

	if not g_instance_map[svr_name][module_name] then
		g_instance_map[svr_name][module_name] = {
			name_map = {},
			obj = nil
		}
	end

	if instance_name then
		if not g_instance_map[svr_name][module_name].name_map[instance_name] then
			g_instance_map[svr_name][module_name].name_map[instance_name] = M:new(svr_name,module_name,instance_name)
		end
		return g_instance_map[svr_name][module_name].name_map[instance_name]
	else
		if not g_instance_map[svr_name][module_name].obj then
			g_instance_map[svr_name][module_name].obj = M:new(svr_name,module_name,instance_name)
		end
		return g_instance_map[svr_name][module_name].obj
	end
end
--指定mod映射数
function M:set_mod_num(num)
	assert(type(num) == 'number')
	self.mod_num = num
	return self
end
--指定访问实例名
function M:set_instance_name(name)
	self.instance_name = name
	return self
end
--指定服务id
function M:set_svr_id(id)
	self.svr_id = id
	return self
end
--------------------------------------------------------------------------------
--one
--------------------------------------------------------------------------------
--用简单轮询负载均衡给单个结点的module_name模板用balance_send的方式发送消息
function M:one_balance_send(...)
	cluster_client:balance_send("balance_send",self.svr_name,"balance_send",self.module_name,...)
end

--用简单轮询负载均衡给单个结点的module_name模板用balance_call的方式发送消息
function M:one_balance_call(...)
	return cluster_client:balance_call("balance_call",self.svr_name,"balance_call",self.module_name,...)
end

--用简单轮询负载均衡给单个结点的module_name模板用mod_send的方式发送消息
function M:one_mod_send(...)
	cluster_client:balance_send("balance_send",self.svr_name,"mod_send",self.module_name,self.mod_num or skynet.self(), ...)
end

--用简单轮询负载均衡给单个结点的module_name模板用mod_call的方式发送消息
function M:one_mod_call(...)
	return cluster_client:balance_call("balance_call",self.svr_name,"mod_call",self.module_name,self.mod_num or skynet.self(),...)
end

--用简单轮询负载均衡给单个结点的module_name模板用broadcast的方式发送消息
function M:one_broadcast(...)
	cluster_client:balance_send("balance_send",self.svr_name,"broadcast",self.module_name,...)
end

--------------------------------------------------------------------------------
--one
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--byid
--------------------------------------------------------------------------------
--用svr_id映射的方式给单个结点的module_name模板用balance_send的方式发送消息
function M:byid_balance_send(...)
	assert(self.svr_id, "not svr_id")
	cluster_client:balance_send("send_by_id",self.svr_name,self.svr_id,"balance_send",self.module_name,...)
end

--用svr_id映射的方式给单个结点的module_name模板用balance_call的方式发送消息
function M:byid_balance_call(...)
	assert(self.svr_id, "not svr_id")
	return cluster_client:balance_call("call_by_id",self.svr_name,self.svr_id,"balance_call",self.module_name,...)
end

--用svr_id映射的方式给单个结点的module_name模板用mod_send的方式发送消息
function M:byid_mod_send(...)
	assert(self.svr_id, "not svr_id")
	cluster_client:balance_send("send_by_id",self.svr_name,self.svr_id,"mod_send",self.module_name,self.mod_num or skynet.self(),...)
end

--用svr_id映射的方式给单个结点的module_name模板用mod_call的方式发送消息
function M:byid_mod_call(...)
	assert(self.svr_id, "not svr_id")
	return cluster_client:balance_call("call_by_id",self.svr_name,self.svr_id,"mod_call",self.module_name,self.mod_num or skynet.self(),...)
end

--用svr_id映射的方式给单个结点的module_name模板用broadcast的方式发送消息
function M:byid_broadcast(...)
	assert(self.svr_id, "not svr_id")
	cluster_client:balance_send("send_by_id",self.svr_name,self.svr_id,"broadcast",self.module_name,...)
end
--------------------------------------------------------------------------------
--all
--------------------------------------------------------------------------------

--给所有结点的module_name模板用balance_send的方式发送消息
function M:all_balance_send(...)
	cluster_client:balance_send("send_all",self.svr_name,"balance_send",self.module_name,...)
end

--给所有结点的module_name模板用balance_call的方式发送消息
function M:all_balance_call(...)
	return cluster_client:balance_call("call_all",self.svr_name,"balance_call",self.module_name,...)
end

--给所有结点的module_name模板用mod_send的方式发送消息
function M:all_mod_send(...)
	cluster_client:balance_send("send_all",self.svr_name,"mod_send",self.module_name,self.mod_num or skynet.self(),...)
end

--给所有结点的module_name模板用mod_call的方式发送消息
function M:all_mod_call(...)
	return cluster_client:balance_call("call_all",self.svr_name,"mod_call",self.module_name,self.mod_num or skynet.self(),...)
end

--给所有结点的module_name模板用broadcast的方式发送消息
function M:all_broadcast(...)
	cluster_client:balance_send("send_all",self.svr_name,"broadcast",self.module_name,...)
end
--------------------------------------------------------------------------------
--all
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--one_by_name
--------------------------------------------------------------------------------

--用简单轮询负载均衡给单个结点的module_name模板用balance_send_by_name的方式发送消息
function M:one_balance_send_by_name(...)
	assert(self.instance_name,"not instance_name")
	cluster_client:balance_send("balance_send",self.svr_name,"balance_send_by_name",self.module_name,self.instance_name,...)
end

--用简单轮询负载均衡给单个结点的module_name模板用balance_call_by_name的方式发送消息
function M:one_balance_call_by_name(...)
	assert(self.instance_name,"not instance_name")
	return cluster_client:balance_call("balance_call",self.svr_name,"balance_call_by_name",self.module_name,self.instance_name,...)
end

--用简单轮询负载均衡给单个结点的module_name模板用mod_send_by_name的方式发送消息
function M:one_mod_send_by_name(...)
	assert(self.instance_name,"not instance_name")
	cluster_client:balance_send("balance_send",self.svr_name,"mod_send_by_name",self.module_name,self.instance_name,self.mod_num or skynet.self(), ...)
end

--用简单轮询负载均衡给单个结点的module_name模板用mod_call_by_name的方式发送消息
function M:one_mod_call_by_name(...)
	assert(self.instance_name,"not instance_name")
	return cluster_client:balance_call("balance_call",self.svr_name,"mod_call_by_name",self.module_name,self.instance_name,self.mod_num or skynet.self(),...)
end

--用简单轮询负载均衡给单个结点的module_name模板用broadcast_by_name的方式发送消息
function M:one_broadcast_by_name(...)
	assert(self.instance_name,"not instance_name")
	cluster_client:balance_send("balance_send",self.svr_name,"broadcast_by_name",self.module_name,self.instance_name,...)
end


--------------------------------------------------------------------------------
--one_by_name
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--byid_by_name
--------------------------------------------------------------------------------

--用svr_id映射的方式给单个结点的module_name模板用balance_send_by_name的方式发送消息
function M:byid_balance_send_by_name(...)
	assert(self.instance_name,"not instance_name")
	assert(self.svr_id,"not svr_id")
	cluster_client:balance_send("send_by_id",self.svr_name,self.svr_id,"balance_send_by_name",self.module_name,self.instance_name,...)
end

--用svr_id映射的方式给单个结点的module_name模板用balance_call_by_name的方式发送消息
function M:byid_balance_call_by_name(...)
	assert(self.instance_name,"not instance_name")
	assert(self.svr_id,"not svr_id")
	return cluster_client:balance_call("call_by_id",self.svr_name,self.svr_id,"balance_call_by_name",self.module_name,self.instance_name,...)
end

--用svr_id映射的方式给单个结点的module_name模板用mod_send_by_name的方式发送消息
function M:byid_mod_send_by_name(...)
	assert(self.instance_name,"not instance_name")
	assert(self.svr_id,"not svr_id")
	cluster_client:balance_send("send_by_id",self.svr_name,self.svr_id,"mod_send_by_name",self.module_name,self.instance_name,self.mod_num or skynet.self(), ...)
end

--用svr_id映射的方式给单个结点的module_name模板用mod_call_by_name的方式发送消息
function M:byid_mod_call_by_name(...)
	assert(self.instance_name,"not instance_name")
	assert(self.svr_id,"not svr_id")
	return cluster_client:balance_call("call_by_id",self.svr_name,self.svr_id,"mod_call_by_name",self.module_name,self.instance_name,self.mod_num or skynet.self(),...)
end

--用svr_id映射的方式给单个结点的module_name模板用broadcast_by_name的方式发送消息
function M:byid_broadcast_by_name(...)
	assert(self.instance_name,"not instance_name")
	assert(self.svr_id,"not svr_id")
	cluster_client:balance_send("send_by_id",self.svr_name,self.svr_id,"broadcast_by_name",self.module_name,self.instance_name,...)
end

--------------------------------------------------------------------------------
--byid_by_name
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--all_by_name
--------------------------------------------------------------------------------
--给所有结点的module_name模板用balance_send_by_name的方式发送消息
function M:all_balance_send_by_name(...)
	assert(self.instance_name,"not instance_name")
	cluster_client:balance_send("send_all",self.svr_name,"balance_send_by_name",self.module_name,self.instance_name,...)
end

--给所有结点的module_name模板用balance_call_by_name的方式发送消息
function M:all_balance_call_by_name(...)
	assert(self.instance_name,"not instance_name")
	return cluster_client:balance_call("call_all",self.svr_name,"balance_call_by_name",self.module_name,self.instance_name,...)
end

--给所有结点的module_name模板用mod_send_by_name的方式发送消息
function M:all_mod_send_by_name(...)
	assert(self.instance_name,"not instance_name")
	cluster_client:balance_send("send_all",self.svr_name,"mod_send_by_name",self.module_name,self.instance_name,self.mod_num or skynet.self(), ...)
end

--给所有结点的module_name模板用mod_call_by_name的方式发送消息
function M:all_mod_call_by_name(...)
	assert(self.instance_name,"not instance_name")
	return cluster_client:balance_call("call_all",self.svr_name,"mod_call_by_name",self.module_name,self.instance_name,self.mod_num or skynet.self(),...)
end

--给所有结点的module_name模板用broadcast_by_name的方式发送消息
function M:all_broadcast_by_name(...)
	assert(self.instance_name,"not instance_name")
	cluster_client:balance_send("send_all",self.svr_name,"broadcast_by_name",self.module_name,self.instance_name,...)
end
--------------------------------------------------------------------------------
--all_by_name
--------------------------------------------------------------------------------

return M