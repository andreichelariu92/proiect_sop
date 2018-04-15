require("http_common")
require("base64")

require("ticket_model")
require ("ticket_view")

require("user_model")
local http_server = require("http.server")
local http_headers = require("http.headers")
local http_util = require("http.util")


local function splitAuthorization(authority)
    -- Remove "Basic" from the begining of the string.
    local b, e = string.find(authority, "Basic ")
    authority = string.sub(authority, e+1)
    --Decode from base64.
    local userPass = fromBase64(authority)
    if userPass == "" then
        return nil
    end
    --Extract user and pass.
    local user = nil
    local pass = nil
    for s in string.gmatch(userPass, "%w+") do
        if user == nil then
            user = s
        elseif pass == nil then
            pass = s
        else
            break
        end
    end
    if user == nil or pass == nil then
        return nil
    end
    return user, pass
end

local function postGrantingTicket(stream)
    local seconds = 2 -- wait 2 seconds to get the request
    local body = stream:get_body_as_string(request)
    
    if not body then
        setHeaders(stream, BAD_REQUEST)
    end
    
    --Parse the request body.
    local user = nil
    local pass = nil
    for key, value in http_util.query_args(body) do
        if key == "user" then
            user = value
        end
        if key == "pass" then
            pass = value
        end
    end
    
    --Check if user data is valid.
    if not user or not pass then
        setHeaders(stream, BAD_REQUEST)
    end
    if not checkUser(user, pass) then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --Create granting ticket.
    local gt = makeGrantingTicket(user, "user")

    --Set the location header to the uri
    --of the new resource.
    local newUri = 
        string.format("/TicketService/GrantingTickets/%s",
                      toHex(gt.key))
    setHeaders(stream, CREATED, newUri)
end

function getGrantingTicket(stream, headers)
    --Get user and password form authorization header.
    local authorization = headers:get("authorization")
    if not authorization then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    local user, pass = splitAuthorization(authorization)
    if user == nil or pass == nil then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    --Verify user.
    local validUser = checkUser(user, pass)
    if not validUser then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    --Extract user key from the uri.
    local uri = headers:get(":path")
    local pattern = "/TicketService/GrantingTickets/(%x+)"
    local userKey = string.match(uri, pattern)
    if not userKey then
        setHeaders(stream, BAD_REQUEST)
    end
    --Get the granting ticket for the corresponding key.
    local gt = searchGrantingTicket(userKey)
    if not gt then
        setHeaders(stream, NOT_FOUND)
    end
    --Prepare the html with the output and write it
    --to the client.
    local html = renderGrantingTicket(gt)
    if not html then
        setHeaders(stream, "500")
    end

    setHeaders(stream, SUCCESS)
    stream:write_chunk(html, true)
end

local ticketController = {
    pattern = string.lower("/TicketService/GrantingTickets"),
    post = postGrantingTicket,
    get = getGrantingTicket
}

return ticketController
