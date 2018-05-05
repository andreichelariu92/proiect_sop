require("base64")

local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require("openssl.ssl.context")
local http_util = require("http.util")

--Create SSL context that accepts self signed certificates.
local context = http_tls:new_client_context()
context:setVerify(openssl_ctx.VERIFY_NONE)

local function createGrantingTicket(context)
    --Perform POST request to create a new granting ticket.
    local request = http_request.new_from_uri("https://localhost:8080/TicketService/GrantingTickets")
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "POST")
    request.headers:append("content-type", "application/x-www-form-urlencoded")
    request:set_body("user=andreichelariu&pass=blah")
    local headers, stream =request:go(100)
    --Save the URI of the new resource.
    local resourceUri = nil
    if headers then
        for k, v in headers:each() do
            if k == "content-location" then
                resourceUri = v
            end
            print(k, v)
        end
    end

    return resourceUri
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

local function getConfigurationFile(ticket)
    --Perform GET request to get the contentx of the file.
    local uri = string.format("https://localhost:8081/DhcpService/ConfigurationFile?ticket=%d",
                    ticket)
    local request = http_request.new_from_uri(uri)
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "GET")
    local headers, stream =request:go(100)
    --Read the status of the request.
    local status = nil
    if headers then
        for k, v in headers:each() do
            if k == ":status" then
                status = v
            end
            print(k, v)
        end
    end

    return status
end

print("")
local grantingTicketUri = createGrantingTicket(context)
print(grantingTicketUri)

print("")
local ticketUri = createTicket("https://localhost:8080" .. grantingTicketUri, "leService", context)
print(ticketUri)

print("")
local ticket = string.match(ticketUri, "/TicketService/Tickets/(%d+)")
ticket = tonumber(ticket)
if not ticket then
    print("Invalid ticket id received from ticket service")
end
local file = getConfigurationFile(ticket)
print(file)
