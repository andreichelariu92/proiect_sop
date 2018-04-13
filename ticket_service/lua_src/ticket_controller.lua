require("http_common")
require("ticket_model")
require("user_model")
local http_server = require("http.server")
local http_headers = require("http.headers")
local http_util = require("http.util")


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
        string.format("/TicketService/grantingTickets/%s",
                      toHex(gt.key))
    setHeaders(stream, CREATED, newUri)
end

function getGrantingTicket(stream)
    local uri = stream:get_headers():get(":path")
end

local ticketController = {
    pattern = string.lower("/TicketService/grantingTickets"),
    post = postGrantingTicket
}

return ticketController
