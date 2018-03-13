RequestService = {}

--GET /RequestService/requests?ticket=t
--GET /RequestService/request_id?ticket=t
function RequestService.get(resource, parameters)
    if resource ~= "requests" and resource ~= 1 then
        return false
    end

    if parameters.ticket ~= "ticket_RequestService" then
        return false
    end

    if resource == "requests" then
        return "List of requests"
    end

    if resource == 1 then
        return "Request with id 1"
    end
end

--POST /RequestService/requests (parameter=new_request), ticket=t
function RequestService.post(resource, parameters)
    if resource ~= "requests" then
        return false
    end

    if parameters.ticket ~= "ticket_RequestService" then
        return false
    end

    if type(parameters.new_request) ~= "string" then
        return false
    end

    return "Request: " .. parameters.new_request .. " has been added"
end

--PUT /RequestService/request_id (parameter=request), ticket=t
function RequestService.put(resource, parameters)
    if resource ~= 1 then
        return false
    end
    
    if parameters.ticket ~= "ticket_RequestService" then
        return false
    end

    if type(parameters.request) ~= "string" then
        return false
    end

    return "New value for request 1: " .. parameters.request
end
--[[
print(RequestService.get("requests", {ticket="ticket_RequestService"}))
print(RequestService.get(1, {ticket="ticket_RequestService"}))
print(RequestService.post("requests", {ticket="ticket_RequestService", new_request="Something"}))
print(RequestService.put(1, {ticket="ticket_RequestService", request="Something"}))
]]--
