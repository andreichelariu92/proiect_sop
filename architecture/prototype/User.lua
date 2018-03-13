require("TicketService")
require("RequestService")
dbg=require("debugger")
User = {}

function User.logIn(user, pass)
    local grantingTicket=TicketService.get("grantingTicket",
        {["user"]=user, ["pass"]=pass})
    return grantingTicket
end

function User.addRequest(grantingTicket)
    local ticket=TicketService.get("ticket",
        {["grantingTicket"]=grantingTicket, service="RequestService"})
    if not ticket then
        return false
    end
    local response = RequestService.post("requests",
        {["ticket"]=ticket, new_request="Una pizza por favor"})
    return response
end

local grantingTicket=User.logIn("user123", "pass")
if grantingTicket then
    print("User loged in successfully")
    local response = User.addRequest(grantingTicket)
    if response then
        print("Request added successfully")
    else
        print("Error adding request")
    end
else
    print("Error logging user")
end
