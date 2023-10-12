local assert = assert
local ARGV = {...}
local skynet_fly_path = ARGV[1]
assert(skynet_fly_path,'缺少 skynet_fly_path')

package.cpath = skynet_fly_path .. "/luaclib/?.so;"
package.path = './?.lua;' .. skynet_fly_path .."/lualib/utils/?.lua;"
local file_util = require "file_util"
local svr_name = file_util.get_cur_dir_name()

local skynet_path = skynet_fly_path .. '/skynet/'
local lua_path = skynet_path .. '/3rd/lua/lua'
local server_path = "./"

local shell_str = "#!bin/bash\n"
shell_str = shell_str .. string.format("%s %s/script/lua/console.lua %s %s get_list | \n",lua_path,skynet_fly_path,skynet_fly_path,svr_name)
shell_str = shell_str .. string.format("xargs curl --http0.9 -s |\n")
shell_str = shell_str .. string.format("xargs %s %s/script/lua/console.lua %s %s find_server_id contriner_mgr 2 | \\\n",lua_path,skynet_fly_path,skynet_fly_path,svr_name)
shell_str = shell_str .. string.format("xargs -I {} %s %s/script/lua/console.lua %s %s reload {} $* | \n",lua_path,skynet_fly_path,skynet_fly_path,svr_name)
shell_str = shell_str .. string.format("xargs curl --http0.9 -s | \n")
shell_str = shell_str .. string.format("xargs %s %s/script/lua/console.lua %s %s handle_reload_result | xargs",lua_path,skynet_fly_path,skynet_fly_path,svr_name)

local shell_path = server_path .. 'script/'

if not os.execute("mkdir -p " .. shell_path) then
	error("create shell_path err")
end

local file_path = shell_path .. 'reload.sh'

local file = io.open(file_path,'w+')
assert(file)
file:write(shell_str)
file:close()
print("make " .. file_path)