require("UserService")

TicketService = {}
--GET /TicketService/grantingTicket?user=u&pass=p
--TODO: Andrei: 
--Should I send the username encrypted with the user's password?
--Instead of the password?
function TicketService.get(resource, parameters)
    if resource == "grantingTicket" then
        local grantingTicket = "ticket_TicketService"
        local user = UserService.get(parameters.user)
        if not user then
            return false
        end

        if user.user ~= parameters.user or
           user.pass ~= parameters.pass then
           return false
        end

       return grantingTicket
   elseif resource == "ticket" then
        if parameters.grantingTicket ~= "ticket_TicketService" then
            return false
        end

        if parameters.service ~= "DHCPService" and parameters.service ~= "RequestService" then
            return false
        end

        if parameters.service == "DHCPService" then
            return "ticket_DHCPService"
        else
            return "ticket_RequestService"

        end

    end

    return false
end

--DELETE /TicketService/grantingTicket_hash?user=u&pass=p
--TODO: The same observation as above
function TicketService.delete(resource, parameters)
    if resource ~= "ticket_TicketService" then
        return false
    end
    
    local user = UserService.get(parameters.user)
    if not user then
        return false
    end

    if user.user ~= parameters.user or
        user.pass ~= parameters.pass then
        return false
    end

    return true
end
--[[
print(TicketService.get("grantingTicket", {user="user123", pass="pass"}))
print(TicketService.get("ticket", {grantingTicket="ticket_TicketService", service="RequestService"}))
print(TicketService.delete("ticket_TicketService", {user="user123", pass="pass"}))
]]--
