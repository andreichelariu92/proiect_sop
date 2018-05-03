-----------------------------------------------------
------------------ Private variables ----------------
-----------------------------------------------------
local gcrypt = require("lua_gcrypt")

local g_key = nil
local g_IV = nil

local function createKey(context,
                serviceName, 
                servicePass)
    --Create http request and populate it,
    local credentials = 
            string.format("serviceName=%s&%pass=%s",                           serviceName,
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

local function readkey(keyUri,
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
    request.ctx = sslContext
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
    local pattern = "<p id=\"key\">%s</p>"
    local key = string.match(html, pattern)
    if not key then
        return nil
    end

    pattern = "<p id=\"IV\">%s</p>"
    local IV = string.match(html, pattern)
    if not IV then
        return nil
    end

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
        return nil
    end

    --GET representation of key
    local html = readKey(keyUri,
                    context,
                    "leService",
                    "blah")
    if not html then
        return nil
    end

    --Parse key representation
    g_key, g_IV = parseKeyHtml(html)
    if not g_key or not g_IV then
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
