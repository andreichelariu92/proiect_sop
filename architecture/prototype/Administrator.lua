require("TicketService")
require("DHCPService")
require("RequestService")
local dbg = require("debugger")

Administrator = {}
function Administrator.logIn(user, pass)
    local grantingTicket = TicketService.get("grantingTicket", {["user"]=user, ["pass"]=pass})
    if grantingTicket then
        return grantingTicket
    else
        return false
    end
end

function Administrator.viewConfigurationFile(grantingTicket)
    if not grantingTicket then
        print("grantingTicket is needed to access DHCPService. Log in to TicketService before accessing this service")
        return false
    end

    local ticket = TicketService.get("ticket",
        {["grantingTicket"] = grantingTicket, service="DHCPService"})
    if not ticket then
        return false
    end

    local fileContent = DHCPService.get("config_file", {["ticket"]=ticket})
    return fileContent
end

function Administrator.startService(grantingTicket)
    if not grantingTicket then
        print("grantingTicket is needed to access DHCPService. Log in to TicketService before accessing this service")
        return false
    end

    local ticket = TicketService.get("ticket",
        {["grantingTicket"] = grantingTicket, service="DHCPService"})
    if not ticket then
        return false
    end
    
    local commandSuccess = DHCPService.post("commands", {["ticket"]=ticket, new_command="start"})
    return commandSuccess
end

function Administrator.viewRequests(grantingTicket)
    if not grantingTicket then
        print("You are out of luck, fool")
        return false
    end

    local ticket = TicketService.get("ticket",
        {["grantingTicket"]=grantingTicket, service="RequestService"})
    if not ticket then
        return false
    end

    local requests = RequestService.get("requests", {["ticket"]=ticket})
    return requests
end

function Administrator.rejectRequest(grantingTicket)
    if not grantingTicket then
        print("You are out of luck, fool")
        return false
    end

    local ticket = TicketService.get("ticket",
        {["grantingTicket"]=grantingTicket, service="RequestService"})
    if not ticket then
        return false
    end
    
    local response = RequestService.put(1, {["ticket"]=ticket, request="rejected beach"})
    return response
end

function Administrator.logOut(user, pass)
    local response = TicketService.delete("ticket_TicketService",
        {["user"] = user, ["pass"]=pass})
    return response
end

grantingTicket = Administrator.logIn("user123", "pass")
if grantingTicket then
    local fileContent = Administrator.viewConfigurationFile(grantingTicket)
    if fileContent then
        print("Configuration file content: " .. fileContent)
    else
        print("Error getting configuration file")
    end

    local commandSuccess = Administrator.startService(grantingTicket)
    if commandSuccess then
        print("DHCP service started successfully")
    else
        print("Error starting DHCP service")
    end

    local requests = Administrator.viewRequests(grantingTicket)
    if requests then
        print("Requests: " .. requests)
    else
        print("Error receiving requests")
    end

    local requestStatus = Administrator.rejectRequest(grantingTicket)
    if requestStatus then
        print("New status for request 1:" .. requestStatus)
    else
        print("Error rejecting request")
    end

    local logoutSuccess = Administrator.logOut("user123", "pass")
    if logoutSuccess then
        print("Logged out successfully")
    else
        print("Error logging out")
    end
end

