local gcrypt = require("lua_gcrypt")
-----------------------------------------------------
---------------- Private variables ------------------
-----------------------------------------------------
local g_serviceKeys = {}


-----------------------------------------------------
----------------Public functions --------------------
-----------------------------------------------------

function makeServiceKey(service_name)
    local key = gcrypt.generateKey()
    local iv = gcrypt.generateIV()

    local output = {
        ["key"] = key,
        ["IV"] = iv,
        ["service_name"] = service_name
    }
    
    g_serviceKeys[key] = output

    return output
end

function searchServiceKey(field, value)
    --Default search is based on key.
    field = field or "key"

    if field == "key" then
        return g_serviceKeys[fromHex(value)]
    end

    if field == "service_name" then
        for _, serviceKey in pairs(g_serviceKeys) do
            if serviceKey.service_name == value then
                return serviceKey
            end
        end

        return nil
    end
end

function removeServiceKey(key)
    g_serviceKeys[fromHex(key)] = nil
end
