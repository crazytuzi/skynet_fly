local skynet_fly_env = require "skynet_fly_env"
local assert = assert
local loadfile = loadfile
local tostring = tostring
local debug_getinfo = debug.getinfo

local M = {}

--添加服务启动之前加载的文件
function M.add_pre_load(path)
	assert(loadfile(path),"can`t loadfile :" ..tostring(path))
	local pre_load = M.get_pre_load()
	if not pre_load then
		pre_load = ""
	end

	pre_load = pre_load .. path .. ";"
	skynet_fly_env.resetenv("preload",pre_load)
end

function M.get_pre_load()
	return skynet_fly_env.getenv("preload")
end

--添加服务启动之后加载的文件
function M.add_after_load(path)
	assert(loadfile(path),"can`t loadfile :" ..tostring(path))
	local old_after_load = M.get_after_load()
	if not old_after_load then
		old_after_load = ""
	end
	old_after_load = old_after_load .. path .. ";"

	skynet_fly_env.resetenv('afterload',old_after_load)
end

function M.get_after_load()
	return skynet_fly_env.getenv('afterload')
end

return M