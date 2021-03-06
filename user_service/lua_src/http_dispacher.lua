local http_server = require("http.server")
local http_headers = require("http.headers")
local user_controller = require("user_controller")
local service_controller = require("service_controller")
local g_controllers = {
    user_controller,
    service_controller
}

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
    for _, controller in ipairs(g_controllers) do
        local match = string.match(uri, controller.pattern)

        if match ~= nil then
            foundUri = true
            foundMethod = controller[method]
            break
        end
    end
    
    --TODO: Andrei: Find logging mechanism
    print("foundUri=", foundUri, 
          " foundMethod=", (foundMethod ~= nil))

    --Execute the handler.
    if not foundUri then
        setHeaders(stream, NOT_FOUND)
    elseif not foundMethod then
        setHeaders(stream, METHOD_NOT_ALLOWED)
    else
        foundMethod(stream, headers)
    end
end

local myServer = http_server.listen({
    host = "localhost",
    port = 8082,
    onstream = dispach,
    tls = true
})

for _, controller in ipairs(g_controllers) do
    if type(controller.init) == "function" then
        controller.init()
    end
end

myServer:listen()
myServer:loop()
