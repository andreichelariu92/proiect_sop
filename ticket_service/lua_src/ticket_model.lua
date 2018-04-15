require("http_common")
------------------------------------------------------------
------------------ Private variables -----------------------
------------------------------------------------------------
local gcrypt = require("lua_gcrypt")

local g_serverKey = gcrypt.generateKey()
local g_serverIV = gcrypt.generateIV()
local AES_BLOCK_SIZE = 16
local g_grantingTickets = {}
------------------------------------------------------------
------------------ Private functions -----------------------
------------------------------------------------------------
local function addPadding(data)
    local dataLen = string.len(data)
    
    if dataLen % AES_BLOCK_SIZE == 0 then
        return data
    end

    local padLen = AES_BLOCK_SIZE - (dataLen % AES_BLOCK_SIZE)
    return data .. string.rep("~", padLen)
end
local function makeUserTable(user, role)
    local output = {}
    output.user = user
    output.role = role
    output.key = gcrypt.generateKey()
    output.IV = gcrypt.generateIV()
    output.startTime = os.time()
    output.endTime = output.startTime + 3600
    
    return output
end

------------------------------------------------------------
------------------ Public functions ------------------------
------------------------------------------------------------

function makeGrantingTicket(user, role)
    -- create granting ticket
    local userTable = makeUserTable(user, role)
    local html = string.format([[
    <html>
    <body>
        <p id="user">%s</p>
        <p id="role">%s</p>
        <p id="key">%s</p>
        <p id="iv">%s</p>
        <p id="startTime">%d</p>
        <p id="endTime">%d</p>
    </body>
    </html>
    ]], userTable.user, 
    userTable.role,
    toHex(userTable.key),
    toHex(userTable.IV),
    userTable.startTime,
    userTable.endTime)
    --encrypt granting ticket with server key 
    local cipher = gcrypt.makeCipher(g_serverKey, g_serverIV)
    local encryptedData = cipher:encrypt(addPadding(html))
    --return encrypted granting ticket, key and IV
    local output = {
        ["blob"] = encryptedData,
        ["key"] = userTable.key,
        ["IV"] = userTable.IV
    }

    g_grantingTickets[output.key] = output
    return output
end

function searchGrantingTicket(userKey)
    return g_grantingTickets[fromHex(userKey)]
end
