local gcrypt = require("lua_gcrypt")
--------------------------------------------------------------------------------
----------------------------- Private variables --------------------------------
--------------------------------------------------------------------------------
local g_serviceKeys = {}


--------------------------------------------------------------------------------
----------------------------- Public functions ---------------------------------
--------------------------------------------------------------------------------

function makeServiceKey(service_name)
    local key = gcrypt.generateKey()
    local iv = gcrypt.generateIV()

    local output = {
        ["key"] = key
        ["IV"] = iv
        ["service_name"] = service_name
    }
    
    g_serviceKeys[key] = output

    return output
end

function searchServiceKey(key)
    return g_serviceKeys[fromHex(key)]
end

function removeServiceKey(key)
    g_serviceKeys[fromHex(key)] = nil
end
