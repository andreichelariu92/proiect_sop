require("base64")

local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require("openssl.ssl.context")
local http_util = require("http.util")

--Create SSL context that accepts self signed certificates.
local context = http_tls:new_client_context()
context:setVerify(openssl_ctx.VERIFY_NONE)

--Perform POST request to create a new granting ticket.
local getRequest = http_request.new_from_uri("https://localhost:8080/TicketService/GrantingTickets")
getRequest.ctx = context
getRequest.tls = true
getRequest.headers:upsert(":method", "POST")
getRequest.headers:append("content-type", "application/x-www-form-urlencoded")
getRequest:set_body("user=andreichelariu&pass=blah")
local headers, stream =getRequest:go(100)
--Save the URI of the new resource.
local resourceUri = nil
if headers then
    print("Headers of POST request: ")
    for k, v in headers:each() do
        if k == "content-location" then
            resourceUri = v
        end
        print(k, v)
    end
end

if not resourceUri then
    print("Error creating resource")
    return
end

print("")

--Perform GET request on the newly created granting ticket.
local getRequest = http_request.new_from_uri("https://localhost:8080" .. resourceUri)
getRequest.ctx = context
getRequest.tls = true
local userPass = toBase64("andreichelariu:blah")
getRequest.headers:upsert(":method", "GET")
getRequest.headers:upsert("authorization","Basic " .. userPass)
local getHeaders, getStream = getRequest:go(100)
--Print headers of the request
print("GET headers ", getHeaders, " getStream ", getStream)
if getHeaders then
    print("Headers of GET request: ")
    for k, v in getHeaders:each() do
        print(k, v)
    end
end
--Print the body of the request (html representation of the granting ticket).
if getStream then
    print(getStream:get_body_as_string())
end

print("")

--Perform DELETE request on the newly created granting ticket.
--[[
local deleteRequest = http_request.new_from_uri("https://localhost:8080" .. resourceUri)
deleteRequest.ctx = context
deleteRequest.tls = true
local userPass = toBase64("andreichelariu:blah")
deleteRequest.headers:upsert(":method", "DELETE")
deleteRequest.headers:upsert("authorization","Basic " .. userPass)
local deleteHeaders, deleteStream = deleteRequest:go(100)
--Print headers of the request
print("DELETE headers ", deleteHeaders, " deleteStream ", deleteStream)
if deleteHeaders then
    print("Headers of DELETE request: ")
    for k, v in deleteHeaders:each() do
        print(k, v)
    end
end
]]--
local function createServiceKey(sslContext)
    local getRequest = http_request.new_from_uri("https://localhost:8080/TicketService/ServiceKeys")
    getRequest.ctx = sslContext
    getRequest.tls = true
    getRequest.headers:upsert(":method", "POST")
    getRequest.headers:append("content-type", "application/x-www-form-urlencoded")
    getRequest:set_body("service_name=leService&pass=blah")
    local headers, stream =getRequest:go(100)
    --Save the URI of the new resource.
    local resourceUri = nil
    if headers then
        print("Headers of POST request: ")
        for k, v in headers:each() do
            if k == "content-location" then
                resourceUri = v
            end
            print(k, v)
        end
    end

    return resourceUri
end

local function readServiceKey(uri, sslContext)
    local authorization = toBase64("leService:blah")
    
    local request = http_request.new_from_uri("https://localhost:8080" .. uri)
    request.ctx = sslContext
    request.tls = true
    request.headers:upsert(":method", "GET")
    request.headers:upsert("authorization", "Basic " .. authorization)
    
    local headers, stream = request:go(100)
    
    if headers then
        print("Headers of GET request: ")
        for k, v in headers:each() do
            print(k, v)
        end
    else
        print("Error reading request ", uri)
    end

    local body = nil
    if stream then
        body = stream:get_body_as_string()
    end

    return body
end

local function deleteServiceKey(uri, sslContext)
    local authorization = toBase64("leService:blah")

    local request = http_request.new_from_uri("https://localhost:8080" .. uri)
    request.ctx = sslContext
    request.tls = true
    request.headers:upsert(":method", "DELETE")
    request.headers:upsert("authorization", "Basic " .. authorization)
    
    local success = false
    local headers, stream = request:go(100)
    if headers then
        print("Headers of DELETE request: ")
        for k, v in headers:each() do
            print(k, v)
            if k == ":status" then
                success = v
            end
        end
    end

    return success
end

local function createTicket(grantingTicketUri, serviceName, sslContext)
    local formParameters = string.format("grantingTicket=%s&serviceName=%s",
                            grantingTicketUri,
                            serviceName)
    local userPass = toBase64("andreichelariu:blah")
    
    local ticketUri = nil

    local postRequest = http_request.new_from_uri("https://localhost:8080/TicketService/Tickets")
    postRequest.ctx = sslContext
    postRequest.tls = true
    postRequest.headers:upsert(":method", "POST")
    postRequest.headers:append("content-type", "application/x-www-form-urlencoded")
    postRequest.headers:upsert("authorization","Basic " .. userPass)

    postRequest:set_body(formParameters)
    
    local headers, stream = postRequest:go(100)
    --Save the URI of the new resource.
    local resourceUri = nil
    if headers then
        print("Headers of POST request: ")
        for k, v in headers:each() do
            if k == "content-location" then
                ticketUri = v
            end
            print(k, v)
        end
    end

    return ticketUri
end

print("")
local serviceKeyUri = createServiceKey(context)
print(serviceKeyUri)

print("")
local serviceKey = readServiceKey(serviceKeyUri, context)
print(serviceKey)
--[[
print("")
local deleteSuccess = deleteServiceKey(serviceKeyUri, context)
print(deleteSuccess)
]]--
print("")
local ticketUri = createTicket("https://localhost:8080" .. resourceUri, "leService", context)
print(ticketUri)
