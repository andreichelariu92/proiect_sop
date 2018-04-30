require("base64")

local http_server = require("http.server")
local http_headers = require("http.headers")

SUCCESS = "200"
CREATED = "201"

BAD_REQUEST = "400"
NOT_AUTHORIZED = "401"
NOT_FOUND = "404"
METHOD_NOT_ALLOWED = "405"

SERVER_ERROR = "500"

function setHeaders(stream, errorCode, location)
    local finishStream = (errorCode ~= "200")

    local headers = http_headers.new()
    headers:append(":status", errorCode)
    headers:append("content-type", "text/html")

    if errorCode == CREATED then
        headers:upsert("content-location", location)
    end
    stream:write_headers(headers, finishStream)
end

--source: https://gist.github.com/yi/01e3ab762838d567e65d
function toHex(str)
    return (str:gsub('.', 
            function (c) 
                return string.format('%02X', string.byte(c)) 
            end))
end
function fromHex(str)
    return (str:gsub('..', 
            function (cc)
                return string.char(tonumber(cc, 16))
            end))
end

function getCredentialsFromHeaders(headers)
    local authority = headers:get("authorization")
    if not authority then
        return nil
    end

    -- Remove "Basic" from the begining of the string.
    local b, e = string.find(authority, "Basic ")
    authority = string.sub(authority, e+1)
    
    --Decode from base64.
    local userPass = fromBase64(authority)
    if userPass == "" then
        return nil
    end

    --Extract user and pass.
    local user = nil
    local pass = nil
    for s in string.gmatch(userPass, "%w+") do
        if user == nil then
            user = s
        elseif pass == nil then
            pass = s
        else
            break
        end
    end
    if user == nil or pass == nil then
        return nil
    end

    return user, pass
end

function getKeyFromHeaders(headers, pattern)
    if not headers or not pattern then
        return nil
    end

    local uri = headers:get(":path")
    if not uri then
        return nil
    end

    local key = string.match(uri, pattern)
    return key
end

