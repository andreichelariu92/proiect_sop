-----------------------------------------------------
------------------ Private variables ----------------
-----------------------------------------------------
local gcrypt = require("lua_gcrypt")

local g_key = nil
local g_IV = nil

local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require("openssl.ssl.context")
local http_util = require("http.util")

    
local function createKey(context,
                serviceName, 
                servicePass)
    --Create http request and populate it,
    local credentials = 
            string.format("service_name=%s&pass=%s",                           serviceName,
                          servicePass)
    local request = http_request.new_from_uri("https://localhost:8080/TicketService/ServiceKeys")
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "POST")
    request.headers:append("content-type", "application/x-www-form-urlencoded")
    request:set_body(credentials)
    
    --Perform request and extract the
    --uri of the ticket.
    local headers, stream =request:go(100)
    local resourceUri = nil
    if headers then
        for k, v in headers:each() do
            if k == "content-location" then
                resourceUri = v
            end
        end
    end

    return resourceUri
end

local function readKey(keyUri,
                context,
                serviceName,
                servicePass)
    --Create http request to GET the service
    --key and populate it.
    local authorization = toBase64(serviceName 
                            .. 
                            ":"
                            ..
                            servicePass)
    local request = http_request.new_from_uri("https://localhost:8080" .. keyUri)
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "GET")
    request.headers:upsert("authorization", "Basic " .. authorization)
    
    --Perform the request and extract
    --the body from it.
    local headers, stream = request:go(100)
    if not headers then
        return nil
    end
    local body = nil
    if stream then
        body = stream:get_body_as_string()
    end

    return body
end

local function parseKeyHtml(html)
    local pattern = "<p id=\"key\">(%x+)</p>"
    local key = string.match(html, pattern)
    if not key then
        return nil
    end
    key = fromHex(key)

    pattern = "<p id=\"IV\">(%x+)</p>"
    local IV = string.match(html, pattern)
    if not IV then
        return nil
    end
    IV = fromHex(IV)

    return key, IV
end
-----------------------------------------------------
------------------ Public functions -----------------
-----------------------------------------------------
function init()
    --Create SSL context that accepts 
    --self signed certificates.
    local context = http_tls:new_client_context()
    context:setVerify(openssl_ctx.VERIFY_NONE)
    
    --Create a key using the TicketService
    local keyUri = createKey(context,
                    "leService",
                    "blah")
    if not keyUri then
        --TODO: Andrei: Find logging mechanism
        print("Error POSTing key to TicketService")
        return nil
    end
    --GET representation of key
    local html = readKey(keyUri,
                    context,
                    "leService",
                    "blah")
    if not html then
        --TODO: Andrei: Find logging mechanism
        print("Error GETting key from TicketService")
        return nil
    end

    --Parse key representation
    g_key, g_IV = parseKeyHtml(html)
    if not g_key or not g_IV then
        --TODO: Andrei: Find logging mechanism
        print("Invalid representation of key")
        return nil
    end

    return true
end

function decryptBlob(blob)
    local cipher = gcrypt.makeCipher(g_key, g_IV)
    local decryptedData = cipher:decrypt(blob)
    cipher = nil --force the cipher to be destroyed

    return decryptedData
end
