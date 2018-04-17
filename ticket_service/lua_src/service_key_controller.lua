require("http_common")
require("service_key_model")
require("service_key_view")

local http_server = require("http.server")
local http_headers = require("http.headers")
local http_util = require("http.util")

local function postServiceKey(stream)
    --Read body of HTTP request.
    local seconds = 2
    local body = stream:get_body_as_string(seconds)

    if not body then
        setHeaders(stream, BAD_REQUEST)
    end
    
    --Read service_name and pass from body.
    local service_name = nil
    local pass = nil
    for key, value in http_util.query_args(body) do
        if key == "service_name" then
            service_name = value
        end
        if key == "pass" then
            pass = value
        end
    end

    --Check if the service is valid.
    if not service_name or not pass then
        setHeaders(stream, BAD_REQUEST)
    end
    if not checkService(service_name, pass) then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Create service key.
    local serviceKey = makeServiceKey(service_name)
    if not serviceKey then
        setHeaders(stream, SERVER_ERROR)
    end

    --Create the URI of the new resource.
    --Send the URI to the user in the Location header.
    local uri = string.format("/TicketService/ServiceKeys/%s",
                    toHex(serviceKey.key))
    setHeaders(stream, CREATED, uri)
end

local function getServiceKey(stream, headers)
    --Get service and pass from authorization header.
    local service_name, pass = getCredentialsFromHeaders(headers)
    if service_name == nil or pass == nil then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --Extract service key from URI.
    local keyPattern = "/TicketService/ServiceKeys/(%x+)"
    local key = getKeyFromHeaders(headers, keyPattern)
    if not key then
        setHeaders(stream, BAD_REQUEST)
    end

    --Check if service credentials exist in the database.
    local validService = checkService(service_name, pass)
    if not validService then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get service key from the in memory list.
    local serviceKey = searchServiceKey(key)
    if not serviceKey then
        setHeaders(stream, NOT_FOUND)
    end

    --Check if the service is the owner of the key.
    if serviceKey.service_name ~= service_name then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Get HTML representation of the service key.
    local html = renderServiceKey(serviceKey)

    --Send the HTML to the user.
    setHeaders(stream, SUCCESS)
    stream:write_chunk(html, true)
end

local function deleteServiceKey(stream, headers)
    --Get service and pass from authorization header.
    local service_name, pass = getCredentialsFromHeaders(headers)
    if service_name == nil or pass == nil then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --Extract service key from URI.
    local keyPattern = "/TicketService/ServiceKeys/(%x+)"
    local key = getKeyFromHeaders(headers, keyPattern)
    if not key then
        setHeaders(stream, BAD_REQUEST)
    end

    --Check if service credentials exist in the database.
    local validService = checkService(service_name, pass)
    if not validService then
        setHeaders(stream, BAD_REQUEST)
    end

    --Check if the service is the owner of the key.
    if serviceKey.service_name ~= service_name then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --TODO: Andrei: Check if the service key exists; if not, return 404.

    --Remove the serviceKey from the in memory list.
    removeServiceKey(key)

    --Set status 200.
    setHeaders(stream, SUCCESS)
    stream:write("", true)
end

local serviceKeyController = {
    pattern = string.lower("/TicketService/ServiceKeys"),
    post = postServiceKey,
    get = getServiceKey,
    delete = deleteServiceKey
}

return serviceKeyController
