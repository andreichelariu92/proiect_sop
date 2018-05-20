require("base64")
require("http_common")

local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require("openssl.ssl.context")
local http_util = require("http.util")
local gcrypt = require("lua_gcrypt")

local function createGrantingTicket(context, user, pass)
    --Perform POST request to create a new granting ticket.
    local request = http_request.new_from_uri("https://localhost:8080/TicketService/GrantingTickets")
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "POST")
    request.headers:append("content-type", "application/x-www-form-urlencoded")
    request:set_body(string.format("user=%s&pass=%s", user, pass))
    local headers, stream =request:go(100)
    
    --Save the URI of the new resource.
    local resourceUri = nil
    print("POST /TicketService/GrantingTickets")
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

local function createTicket(userPass, grantingTicketUri, serviceName, sslContext)
    local formParameters = string.format("grantingTicket=%s&serviceName=%s",
                            grantingTicketUri,
                            serviceName)
    
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

local function getConfigurationFile(ticket, context)
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
    
    if status == "200" then
        return status, stream:get_body_as_string()
    else
        return status
    end
end

local function getGrantingTicket(uri, userPass, context)
    --Perform GET request to create a new granting ticket.
    local request = http_request.new_from_uri("https://localhost:8080" .. uri)
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "GET")
    request.headers:append("content-type", "application/x-www-form-urlencoded")
    request.headers:upsert("authorization","Basic " .. userPass)

    local headers, stream =request:go(100)
    
    --Save the URI of the new resource.
    local status = nil
    print("GET", uri)
    if headers then
        for k, v in headers:each() do
            if k == ":status" then
                status = v
            end
            print(k, v)
        end
    end

    if status == "200" then
        return status, stream:get_body_as_string()
    else
        return status
    end
end
--[[
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
local status, file = getConfigurationFile(ticket)
print(file)
]]--

--Create SSL context that accepts self signed certificates.
local g_context = http_tls:new_client_context()
g_context:setVerify(openssl_ctx.VERIFY_NONE)

local g_grantingTicketUri = nil
local g_dhcpTicketUri = nil
local g_user = nil
local g_pass = nil
local g_fileContent = nil

local function getTicketId(ticketUri)
    local ticketId = string.match(ticketUri, "/TicketService/Tickets/(%d+)")
    return tonumber(ticketId)
end

local function parseGrantingTicket(html)
    local pattern = "<p id=\"key\">(%x+)</p>"
    local key = string.match(html, pattern)
    if not key then
        return nil
    end
    key = fromHex(key)

    pattern = "<p id=\"iv\">(%x+)</p>"
    local iv = string.match(html, pattern)
    if not iv then
        return nil
    end
    iv = fromHex(iv)

    return key, iv
end

local function parseConfigurationFile(html)
    local pattern = "<p id=\"blob\">(%x+)</p>"
    local blob = string.match(html, pattern)
    if not blob then
        return nil
    end

    return fromHex(blob)
end

function login(user, pass)
    local uri = createGrantingTicket(g_context, user, pass)
    if uri then
        g_grantingTicketUri = uri
        g_user = user
        g_pass = pass
        return true
    else
        return false
    end
end

function createDhcpTicket()
    if not g_user or not g_pass then
        return nil
    end
    local userPass = toBase64(string.format("%s:%s", g_user, g_pass))
    
    local uri = createTicket(userPass, g_grantingTicketUri, "leService", g_context)
    if not uri then
        return false
    end

    g_dhcpTicketUri = uri
    return true
end

function readConfigurationFile()
    --Get ticket id from the ticket URI.
    local ticketId = getTicketId(g_dhcpTicketUri)
    if not ticketId then
        return false
    end
    
    --Make GET request for configuration file.
    local status, body = 
        getConfigurationFile(ticketId, g_context)
    if status ~= "200" then
        return false
    end
    print("Content of DHCP config file\n", body)
    
    --Extract encrypted configuration file.
    local encryptedFile = parseConfigurationFile(body)
    if not encryptedFile then
        return false
    end
    
    --Make GET request for granting ticket.
    local userPass = toBase64(string.format("%s:%s", g_user, g_pass))
    local status, grantingTicket = getGrantingTicket(g_grantingTicketUri, userPass, g_context)
    print("Content of granting ticket\n", grantingTicket)
    if status ~= "200" then
        return false
    end
    
    --Get key and initialization vector from granting ticket.
    local key, iv = parseGrantingTicket(grantingTicket)
    
    --Decrypt configuration file.
    local cypher = gcrypt.makeCipher(key, iv)
    g_fileContent = cypher:decrypt(encryptedFile)

    return true
end

function getFileContent()
    return g_fileContent
end
