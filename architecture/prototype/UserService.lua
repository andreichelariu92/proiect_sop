UserService = {}

--GET /UserService/user_name
function UserService.get(resource, parameters)
    if resource ~= "user123" then
        return false
    end
    
    response = {}
    response.user = "user123"
    response.pass = "pass"

    return response
end

-- POST /UserService/users
function UserService.post(resource, parameters)
    if resource ~= "users" then
        return false
    end

    if type(parameters.user) ~= "string" and 
       type(parameters.pass) ~= "string" then
        return false
    end

    return true
end
