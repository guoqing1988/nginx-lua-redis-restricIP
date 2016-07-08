-- global configure for redis server
local redis_server = "127.0.0.1"
local redis_port = 6379
local redis_timeout = 1000
local redis_database = 1

-- Lua script
local redis = require "resty.redis"
local red = redis:new()

red:set_timeout(redis_timeout)
local ok, err = red:connect(redis_server, redis_port)
if not ok then
    ngx.log(ngx.STDERR, "Can't connect to redis server")
    return
end
red:select(redis_database)

local client_ip = ngx.var.remote_addr
local res, err = red:sismember("ip",client_ip)
if err then
    ngx.log(ngx.STDERR, err)
    return
end

if res == 1 then
    ngx.log(ngx.INFO, "IP: " .. client_ip .. " in black list")
    ngx.exit(ngx.HTTP_FORBIDDEN)
end
return
