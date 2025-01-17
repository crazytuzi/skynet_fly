local skynet = require "skynet"
local mod_config = require "mod_config"
local table_util = require "table_util"
require "manager"

local table = table
local ipairs = ipairs

--这是可热更服务的启动

local M = {}

function M.run()
    skynet.monitor('monitor_exit')
    local cmgr = skynet.uniqueservice('contriner_mgr')
	skynet.uniqueservice("debug_console", skynet.getenv('debug_port'))

    local before_run_list = {} --先跑
    local delay_run_list = {}  --延迟再次调用再跑
	for mod_name,mod_cfg in table_util.sort_ipairs(mod_config,function(a,b)
		return a.launch_seq < b.launch_seq
	end) do
        if not mod_cfg.delay_run then
            table.insert(before_run_list,mod_name)
        else
            table.insert(delay_run_list,mod_name)
        end
	end

    skynet.call(cmgr,'lua','load_modules',table.unpack(before_run_list))
    return function()
        if not delay_run_list then return end
        skynet.call(cmgr,'lua','load_modules',table.unpack(delay_run_list))
        delay_run_list = nil
    end
end

return M