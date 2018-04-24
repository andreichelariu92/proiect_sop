require("http_common")

require("granting_ticket_model")
require ("granting_ticket_view")

require("user_model")

local http_server = require("http.server")
local http_headers = require("http.headers")
local http_util = require("http.util")


local function postGrantingTicket(stream)
    local seconds = 2 -- wait 2 seconds to get the request
    local body = stream:get_body_as_string(seconds)
    
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
    local user, pass = getCredentialsFromHeaders(headers)
    if user == nil or pass == nil then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --Extract user key from the uri.
    local pattern = "/TicketService/GrantingTickets/(%x+)"
    local userKey = getKeyFromHeaders(headers, pattern)
    if not userKey then
        setHeaders(stream, BAD_REQUEST)
    end
    
    --Check if user exists in database.
    local validUser = checkUser(user, pass)
    if not validUser then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Check if user is the owner of the ticket.
    local owner = getGrantingTicketOwner(userKey)
    if owner ~= user then
        setHeaders(stream, NOT_AUTHORIZED)
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

local function deleteGrantingTicket(stream, headers)
    --Get user and password form authorization header.
    local user, pass = getCredentialsFromHeaders(headers)
    if user == nil or pass == nil then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Extract user key from the uri.
    local pattern = "/TicketService/GrantingTickets/(%x+)"
    local userKey = getKeyFromHeaders(headers, pattern)
    if not userKey then
        setHeaders(stream, BAD_REQUEST)
    end

    --Check the user exists in the database.
    local validUser = checkUser(user, pass)
    if not validUser then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Check the user is the owner of the ticket
    local owner = getGrantingTicketOwner(userKey)
    if owner ~= user then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --TODO: Andrei: Check if the ticket exists; if not, return 404.
    
    --Delete the granting ticket from the in memory list.
    removeGrantingTicket(userKey)
    --Set status to 200.
    setHeaders(stream, SUCCESS)
    stream:write_chunk("", true)
end

local grantingTicketController = {
    pattern = string.lower("/TicketService/GrantingTickets"),
    post = postGrantingTicket,
    get = getGrantingTicket,
    delete = deleteGrantingTicket
}

return grantingTicketController
