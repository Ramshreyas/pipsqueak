-- get url path
local q1 = ngx.var[1]
local q2 = ngx.var[2]
local q3 = ngx.var[3]

-- get post args
local post_params = ""
ngx.req.read_body()
local args, err = ngx.req.get_post_args()
if not args then
  ngx.say("no post args", err)
  return
end
for key, val in pairs(args) do
  post_params = post_params .. key .. "='" .. val .. "', "
end
post_params = post_params:sub(1, -3)

-- construct sql query
local query = "NA"
if q3 then
  query = "update " .. q1 .. " set " ..post_params .." where " .. q2 .. " = '" .. q3 .. "'"
end

-- instantiate db
local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
  ngx.say("failed to instantiate mysql: ", err)
  return
end

db:set_timeout(1000) -- 1 sec

-- connect to db
local ok, err, errno, sqlstate = db:connect{
 host = "127.0.0.1",
 port = 3306,
 database = "smartjobdb",
 user = "root",
 password = "^CyLRx3J8mm",
 max_packet_size = 1024 * 1024 }

if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
  return
end

-- run the query
res, err, errno, sqlstate = db:query(query, 10)
if not res then
  ngx.status = 400
  ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
  ngx.exit(ngx.HTTP_OK)
  return
end

-- format the result as json
local cjson = require "cjson"
ngx.say(cjson.encode(res))

-- put it into the connection pool of size 100,
-- with 10 seconds max idle timeout
local ok, err = db:set_keepalive(10000, 100)
if not ok then
  ngx.say("failed to set keepalive: ", err)
  return
end
