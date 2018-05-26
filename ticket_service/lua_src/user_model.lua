local http_request = require("http.request")
local http_tls = require("http.tls")
local openssl_ctx = require("openssl.ssl.context")

local function getUser(userName, context)
    local uri = string.format("https://localhost:8082/UserService/Users/%s", userName)
    
    local request = http_request.new_from_uri(uri)
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "GET")
    
    local headers, stream =request:go(100)
    --Read the status of the request.
    local status = nil
    if headers then
        for k, v in headers:each() do
            if k == ":status" then
                status = v
            end
            print(k, v)
        end
    end
    
    if status == "200" then
        local body = stream:get_body_as_string()
        return status, body
    else
        return status
    end
end

local function getService(serviceName, context)
    local uri = string.format("https://localhost:8082/UserService/Services/%s", serviceName)
    
    local request = http_request.new_from_uri(uri)
    request.ctx = context
    request.tls = true
    request.headers:upsert(":method", "GET")
    
    local headers, stream =request:go(100)
    --Read the status of the request.
    local status = nil
    if headers then
        for k, v in headers:each() do
            if k == ":status" then
                status = v
            end
            print(k, v)
        end
    end
    
    if status == "200" then
        local body = stream:get_body_as_string()
        return status, body
    else
        return status
    end
end

local function parseService(html)
    local pattern = "<p id=\"id\">(%d+)</p>"
    local id = string.match(html, pattern)
    if not id then
        return nil
    end
    id = tonumber(id)

    pattern = "<p id=\"name\">(%w+)</p>"
    local name = string.match(html, pattern)
    if not name then
        return nil
    end

    pattern = "<p id=\"password\">(%w+)</p>"
    local password = string.match(html, pattern)
    if not password then
        return nil
    end

    local s = {
        ["id"] = id,
        ["name"] = name,
        ["password"] = password
    }
    return s
end

local function parseUser(html)
    local pattern = "<p id=\"id\">(%d+)</p>"
    local id = string.match(html, pattern)
    if not id then
        return nil
    end
    id = tonumber(id)

    pattern = "<p id=\"name\">(%w+)</p>"
    local name = string.match(html, pattern)
    if not name then
        return nil
    end

    pattern = "<p id=\"password\">(%w+)</p>"
    local password = string.match(html, pattern)
    if not password then
        return nil
    end

    local u = {
        ["id"] = id,
        ["name"] = name,
        ["password"] = password
    }
    return u
end

function checkUser(user, pass)
    local context = http_tls:new_client_context()
    context:setVerify(openssl_ctx.VERIFY_NONE)

    local status, userHtml = getUser(user, context)
    if status ~= "200" then
        return false
    end
    
    local u = parseUser(userHtml)
    if not u then
        return false
    end
    
    if u.password ~= pass then
        return false
    end
    
    return true
end

function checkService(service, pass)
    local context = http_tls:new_client_context()
    context:setVerify(openssl_ctx.VERIFY_NONE)

    local status, serviceHtml = getService(service, context)
    if status ~= "200" then
        return false
    end
    
    local s = parseService(serviceHtml)
    if not s then
        return false
    end
    
    if s.password ~= pass then
        return false
    end
    
    return true
end
