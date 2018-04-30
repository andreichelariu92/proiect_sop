require("http_common")
require("granting_ticket_view")
require("granting_ticket_model")

local http_server = require("http.server")
local http_headers = require("http.headers")
local http_util = require("http.util")

local function getKeyFromUri(uri)
    local pattern = 
            "/TicketService/GrantingTickets/(%x+)"
    return string.match(uri, pattern)
end

local function postTicket(stream, headers)
    --Read body.
    local seconds = 2 --timeout of 2 seconds
    local body = stream:get_body_as_string(seconds)
    if not body then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get arguments from body.
    local grantingTicketUri = nil
    local serviceName = nil
    for key, value in http_util.query_args(body) do
        if key == "grantingTicket" then
            grantingTicketUri = value
        end
        if key == "serviceName" then
            serviceName = value
        end
    end
    if not grantingTicketUri or not serviceName then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get service key.
    local serviceKey = searchServiceKey(
                        "service_name",
                        serviceName)
    if not serviceKey then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get granting ticket.
    local gt = searchGrantingTicket(
                getKeyFromUri(grantingTicketUri))
    if not gt then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get user and pass form authorization header.
    local user, pass = 
        getCredentialsFromHeaders(headers)
    if user == nil or pass == nil then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Check if user exists in database.
    local validUser = checkUser(user, pass)
    if not validUser then
        setHeaders(stream, NOT_AUTHORIZED)
    end
    
    --Check if user is the owner 
    --of the granting ticket.
    if gt.user ~= user then
        setHeaders(stream, NOT_AUTHORIZED)
    end

    --Make ticket.
    local ticket = makeTicket(gt, serviceKey)
    if not ticket then
        setHeaders(stream, SERVER_ERROR)
    end
    
    --Set location header to the URI 
    --of the new resource.
    local newUri = string.format(
                    "/TicketService/Tickets/%d", 
                    ticket.id)

    --Return status code.
    setHeaders(stream, CREATED, newUri)
end

local function getTicket(stream, headers)
    --Extract ticket id from URI.
    local pattern = "/TicketService/Tickets/(%d+)"
    local ticketId = getKeyFromHeaders(headers, 
                        pattern)
    ticketId = tonumber(ticketId)
    if not ticketId then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get the ticket from the in memory list.
    local ticket = searchTicket(ticketId)
    if not ticket then
        setHeaders(stream, NOT_FOUND)
    end

    --Prepare the html to be sent to the client.
    local html = renderTicket(ticket)
    if not html then
        setHeaders(stream, SERVER_ERROR)
    end

    --Send the representation to the client.
    setHeaders(stream, SUCCESS)
    stream:write_chunk(html, true)
end

local ticketController = {
    pattern = string.lower("/TicketService/Tickets"),
    ["post"] = postTicket,
    ["get"] = getTicket
}

return ticketController
