-- get url path
local q1 = ngx.var[1]
local q2 = ngx.var[2]

-- get post body
local body = ""
ngx.req.read_body()
body = ngx.req.get_body_data()

-- construct sql query
local query = "NA"
if q2 then
  query = "select * from " .. q1 .. " where " .. q2 .. " in (" .. body .. ")"
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
