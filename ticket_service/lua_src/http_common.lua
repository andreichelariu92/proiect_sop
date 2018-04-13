local http_server = require("http.server")
local http_headers = require("http.headers")

SUCCESS = "200"
CREATED = "201"

BAD_REQUEST = "400"
NOT_AUTHORIZED = "401"
NOT_FOUND = "404"
METHOD_NOT_ALLOWED = "405"

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
