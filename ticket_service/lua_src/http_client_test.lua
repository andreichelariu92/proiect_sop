require("base64")

local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require "openssl.ssl.context"

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
