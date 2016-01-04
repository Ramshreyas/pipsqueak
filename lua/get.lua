-- Get URI args
local q1 = ngx.var[1]
local q2 = ngx.var[2]
local q3 = ngx.var[3]
local q4 = ngx.var[4]
local q5 = ngx.var[5]

-- Get query parameters
local limit = " "
local offset = " "
local order = " "
local asc = " "
local desc = " "
local query_params, err = ngx.req.get_uri_args()
if query_params["limit"] then
	limit = " limit " .. query_params["limit"]
end
if query_params["offset"] then
	offset = " offset " .. query_params["offset"]
end
if query_params["order"] then
	order = " order by " .. query_params["order"]
end
if query_params["asc"] then
	asc = " asc "
end
if query_params["desc"] then
	desc = " desc "
end

-- construct sql query
local query = ""
if q5 then
  query = "select * from " .. q1 .. " where " .. q2 .. " = '" .. q3 .. "' and " .. q4 .. " = '" .. q5 .. "'" .. order .. asc .. desc .. limit .. offset
elseif q4 then
  query = "select * from " .. q1 .. " where " .. q2 .. " between '" .. q3 .."' and '" .. q4 .. "'" .. order .. asc .. desc .. limit .. offset
elseif q3 then
  query = "select * from " .. q1 .. " where " .. q2 .. " = '" .. q3 .. "'" .. order .. asc .. desc .. limit .. offset
elseif q2 then
  query = "select " .. q2 .. " from " .. q1 .. order .. asc .. desc .. limit .. offset
elseif q1 then
  query = "select * from " .. q1 .. order .. asc .. desc .. limit .. offset
else
  query = "show tables"
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

