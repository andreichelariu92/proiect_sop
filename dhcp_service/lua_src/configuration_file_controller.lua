require("http_common")
require("configuration_file_model")
require("configuration_file_view")

local http_server = require("http.server")
local http_headers = require("http.headers")
local http_util = require("http.util")
local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require("openssl.ssl.context")

local function getTicket(ticketId)
    --Configure SSL context.
    local sslContext = http_tls:new_client_context()
    sslContext:setVerify(openssl_ctx.VERIFY_NONE)
    
    --Perform HTTP GET request
    local ticketUri = 
        "https://localhost:8080/TicketService/Tickets/" 
        .. 
        ticketId
    local request = http_request.new_from_uri(ticketUri)
    request.ctx = sslContext
    request.tls = true
    request.headers:upsert(":method", "GET")
    local headers, stream = request:go(100)
    
    --Check status in HTTP headers.
    local status = nil
    if not headers then
        return nil
    end
    for k, v in headers:each() do
        if k == ":status" then
            status = v
        end
    end
    if status ~= "200" then
        return nil
    end

    --Extract the html representation from the body.
    if not stream then
        return nil
    end
    local html = stream:get_body_as_string()
    return html
end

local function extractBlob(html)
    local pattern = "<p id=\"blob\">(%x+)</p>"
    local blob = string.match(html, pattern)
    if blob then
        return fromHex(blob)
    else
        return nil
    end
end

local function extractTicketTable(html)
    local pattern = "<p id=\"user\">(%w+)</p>"
    local user = string.match(html, pattern)
    if not user then
        return nil
    end

    pattern = "<p id=\"role\">(%w+)</p>"
    local role = string.match(html, pattern)
    if not role then
        return nil
    end

    pattern = "<p id=\"key\">(%x+)</p>"
    local key = string.match(html, pattern)
    if not key then
        return nil
    end
    key = fromHex(key)
    
    pattern = "<p id=\"iv\">(%x+)</p>"
    local IV = string.match(html, pattern)
    if not IV then
        return nil
    end
    IV = fromHex(IV)
    
    pattern = "<p id=\"startTime\">(%d+)</p>"
    local startTime = string.match(html, pattern)
    startTime = tonumber(startTime)
    if not startTime then
        return nil
    end
    
    pattern = "<p id=\"endTime\">(%d+)</p>"
    local endTime = string.match(html, pattern)
    endTime = tonumber(endTime)
    if not endTime then
        return nil
    end
    
    pattern = "<p id=\"currentTime\">(%d+)</p>"
    local currentTime = string.match(html, pattern)
    currentTime = tonumber(currentTime)
    if not currentTime then
        return nil
    end

    local output = {
        ["user"] = user,
        ["role"] = role,
        ["key"] = key,
        ["IV"] = IV,
        ["startTime"] = startTime,
        ["endTime"] = endTime,
        ["currentTime"] = currentTime
    }
    return output
end

local function decryptTicket(ticketHtml)
    --Extract blob from html
    local blob = extractBlob(ticketHtml)
    if not blob then
        return nil, "500"
    end

    --Decrypt the blob.
    local decryptedHtml = decryptBlob(blob)
    if not decryptedHtml then
        return nil, "401"
    end
    
    --Extract the data from the html
    local ticketTable = extractTicketTable(decryptedHtml)
    if not ticketTable then
        return nil, "500"
    end

    return ticketTable
end

local function getConfigurationFile(stream, headers)
    --Get ticket id from uri parameter.
    local pattern = 
            "/DhcpService/ConfigurationFile%?ticket=(%d+)"
    local ticketId = getKeyFromHeaders(headers, pattern)
    ticketId = tonumber(ticketId)
    if not ticketId then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get ticket from ticket service.
    local ticketHtml = getTicket(ticketId)
    if not ticketHtml then
        setHeaders(stream, BAD_REQUEST)
    end

    --Decrypt ticket with the service key and IV.
    local ticket, status = decryptTicket(ticketHtml)
    if not ticket then
        setHeaders(stream, status)
    end
    
    --Read content of file
    local text, err = readConfigurationFile(ticket)
    if not text then
        if err == "timeout" then
            setHeaders(stream, TIMEOUT)
        elseif err == "not authorized" then
            setHeaders(stream, NOT_AUTHORIZED)
        elseif err == "internal error" then
            setHeaders(stream, SERVER_ERROR)
        end
    end

    --Encrypt text with user key and IV.
    local fileBlob = encryptFile(text, 
                        ticket.key, 
                        ticket.IV)
    
    --Form html and send it to user
    local html = renderFile(fileBlob)
    if not html then
        setHeaders(stream, SERVER_ERROR)
    end
    
    setHeaders(stream, SUCCESS)
    stream:write_chunk(html, true)
end

local handlers = {
    ["pattern"] = string.lower("/DhcpService/ConfigurationFile"),
    ["get"] = getConfigurationFile,
    ["init"] = init
}
return handlers
