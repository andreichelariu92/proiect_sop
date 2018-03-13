DHCPService = {}

--GET /DHCPService/config_file?ticket=t
--GET /DHCPService/command?ticket=t
function DHCPService.get(resource, parameters)
    if resource ~= "config_file" and resource ~= "command" then
        return false
    end

    if parameters.ticket ~= "ticket_DHCPService" then
            return false
    end

    if resource == "config_file" then
        return "Configuration file content"
    end

    if resource == "command" then
        return "start"
    end
end

-- POST /DHCPService/config_file(ticket=t and file_content=content to be appended)
-- POST /DHCPService/command(ticket=t and new_command=command to be executed)
function DHCPService.post(resource, parameters)
    if resource ~= "config_file" and resource ~= "commands" then
        return false
    end

    if parameters.ticket ~= "ticket_DHCPService" then
        return false
    end

    if resource == "config_file" then
        if type(parameters.file_content) ~= "string" then
            return false
        end

        return "Configuration file content: " .. parameters.file_content
    end
    if resource == "commands" then
        if type(parameters.new_command) ~= "string" then
            return false
        end

        return "Command to service: " .. parameters.new_command
    end
end
--[[
print(DHCPService.get("command", {ticket="ticket_DHCPService"}))
print(DHCPService.get("config_file", {ticket="ticket_DHCPService"}))
print(DHCPService.post("config_file", {ticket="ticket_DHCPService", file_content="Red hot chilli peppers"}))
print(DHCPService.post("command", {ticket="ticket_DHCPService", new_command="sudo make me a sandwitch"}))
]]--
