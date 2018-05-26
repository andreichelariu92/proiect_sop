local driver = require("luasql.sqlite3")
local env = driver.sqlite3()

function searchUser(userName)
    if not userName then
        return nil, "invalid input"
    end
    
    --create connection to the database 
    local connection = env:connect("users_db")
    
    --create query string
    local query = string.format("SELECT * FROM users WHERE name='%s'", userName)
    local cursor, err = connection:execute(query)
    if not cursor then
        return nil, err
    end

    --fetch the user using the cursor
    local row = cursor:fetch({}, "a")
    if not row then
        return nil, "internal error"
    end

    --create table with user data and return the table
    local user = {
        ["id"] = row.id,
        ["name"] = row.name,
        ["password"] = row.password
    }

    return user
end

function searchService(serviceName)
    if not serviceName then
        return nil, "invalid input"
    end
    
    --create connection to the database 
    local connection = env:connect("services_db")
    
    --create query string
    local query = string.format("SELECT * FROM services WHERE name='%s'", serviceName)
    local cursor, err = connection:execute(query)
    if not cursor then
        return nil, err
    end

    --fetch the user using the cursor
    local row = cursor:fetch({}, "a")
    if not row then
        return nil, "internal error"
    end

    --create table with service data and return the table
    local service = {
        ["id"] = row.id,
        ["name"] = row.name,
        ["password"] = row.password
    }

    return service
end
