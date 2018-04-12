local http_server = require("http.server")
local http_headers = require("http.headers")

local g_requestHandlers = {}
--[[
local function handlePost(stream)
    --TODO: Andrei: Remove
    print("handlePost called")
    local res_headers = http_headers.new()
    res_headers:append(":status", "200")
    res_headers:append("content-type", "text/html")
    -- Send headers to client; end the stream immediately if this was a HEAD request
    --assert(stream:write_headers(res_headers, req_method == "HEAD"))
    stream:write_headers(res_headers, false)
    stream:write_chunk("<html><body><p>Am pula mare</p></body></html>", true)
end
local requestHandler = {
    pattern = "/ticketservice/grantingtickets",
    post = handlePost
}

local function sendErrorCode(stream, errorCode)
    local headers = http_headers.new()
    headers:append(":status", errorCode)
    headers:append("content-type", "text/html")
    stream:writeHeaders(headers, true)
end

]]--
local function dispach(myServer, stream)
    --Extract method and URI from http request.
    local headers = stream:get_headers()
    local method = string.lower(headers:get(":method"))
    local uri = string.lower(headers:get(":path"))
    
    --TODO: Andrei: Find a logging mechanism
    print("Request made for: ", method, uri)

    --Find a request handler that matches the URI.
    --Find a function inside the request handler 
    --that matches the HTTP method.
    local foundUri = false
    local foundMethod = nil
    for _, requestHandler in ipairs(g_requestHandlers) do
        local match = string.match(uri, requestHandler.pattern)

        if match ~= nil then
            foundUri = true
            foundMethod = requestHandler[method]
            break
        end
    end
    
    --TODO: Andrei: Find logging mechanism
    print("foundUri=", foundUri, " foundMethod=", foundMethod)

    --Execute the handler.
    if not foundUri then
        sendErrorCode(stream, "404")
    elseif not foundMethod then
        sendErrorCode(stream, "405")
    else
        foundMethod(stream)
    end
end

local myServer = http_server.listen({
    host = "localhost",
    port = 8080,
    onstream = dispach,
    tls = true
})
myServer:listen()
myServer:loop()
