local util = require 'raven.util'

local parse_dsn = util.parse_dsn
local generate_auth_header = util.generate_auth_header
local _VERSION = util._VERSION
local _M = {}

local mt = {}
mt.__index = mt

function mt:send(json_str)
    local auth = generate_auth_header(self)
    local headers = {}
    headers[":method"] = "POST"
    headers[":authority"] = self.host
    headers[":path"] = self.request_uri
    headers["content-type"] = "application/json"
    headers["content-length"] = #json_str
    headers["user-agent"] = "raven-lua-envoy/" .. _VERSION
    headers["x-sentry-auth"] = auth
    headers = self.handle:httpCall(self.cluster, headers, json_str,
        10000, self.async)
    if (self.async) then
      return true
    end
    if (headers[":status"]) ~= "200" then
      return true
    end
    return nil, "server responded with status: " .. (headers[":status"] or "none")
end

function _M.new(conf)
    local obj, err = parse_dsn(conf.dsn)
    if not obj then
        return nil, err
    end

    if conf.async == nil then
      obj.async = true
    else
      obj.async = conf.async
    end

    if not conf.cluster then
        return nil, "cluster required"
    end
    obj.cluster = conf.cluster
    if not conf.cluster then
        return nil, "handle required"
    end
    obj.handle = conf.handle

    return setmetatable(obj, mt)
end
return _M
