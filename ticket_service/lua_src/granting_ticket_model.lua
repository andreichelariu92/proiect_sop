require("http_common")
-----------------------------------------------------
------------------ Private variables ----------------
-----------------------------------------------------
local gcrypt = require("lua_gcrypt")

local g_serverKey = gcrypt.generateKey()
local g_serverIV = gcrypt.generateIV()
local AES_BLOCK_SIZE = 16
local g_grantingTickets = {}
local g_tickets = {}
-----------------------------------------------------
------------------ Private functions ----------------
-----------------------------------------------------
local function addPadding(data)
    local dataLen = string.len(data)
    
    if dataLen % AES_BLOCK_SIZE == 0 then
        return data
    end

    local padLen = AES_BLOCK_SIZE - 
                   (dataLen % AES_BLOCK_SIZE)
    return data .. string.rep("~", padLen)
end
local function makeUserTable(user, 
                role, 
                key, 
                IV, 
                startTime, 
                endTime)
    local output = {}
    output.user = user
    output.role = role
    output.key = key or gcrypt.generateKey()
    output.IV = IV or gcrypt.generateIV()
    output.startTime = startTime or os.time()
    output.endTime = 
        endTime or (output.startTime + 3600)
    
    return output
end
local function parseUserTable(html)
    local pattern = "<p id=\"user\">(%w+)</p>"
    local user = string.match(html, pattern)
    if not user then
        return nil
    end

    pattern = "<p id=\"role\">(%w+)</p>"
    local role = string.match(html, pattern)
    if not role then
        return nil
    end

    pattern = "<p id=\"key\">(%x+)</p>"
    local key = string.match(html, pattern)
    if not key then
        return nil
    end
    key = fromHex(key)
    
    pattern = "<p id=\"iv\">(%x+)</p>"
    local IV = string.match(html, pattern)
    if not IV then
        return nil
    end
    IV = fromHex(IV)
    
    pattern = "<p id=\"startTime\">(%d+)</p>"
    local startTime = string.match(html, pattern)
    if not startTime then
        return nil
    end
    
    pattern = "<p id=\"endTime\">(%d+)</p>"
    local endTime = string.match(html, pattern)
    if not endTime then
        return nil
    end

    return makeUserTable(user, 
            role, 
            key, 
            IV, 
            startTime, 
            endTime)
end
-----------------------------------------------------
------------------ Public functions -----------------
-----------------------------------------------------

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

    --encrypt granting ticket with the service key
    local cipher = gcrypt.makeCipher(g_serverKey, 
                    g_serverIV)
    local encryptedData = 
            cipher:encrypt(addPadding(html))
    --return encrypted granting ticket, key and IV
    local output = {
        ["blob"] = encryptedData,
        ["key"] = userTable.key,
        ["IV"] = userTable.IV,
	    ["user"] = userTable.user
    }

    g_grantingTickets[output.key] = output
    return output
end

function searchGrantingTicket(userKey)
    return g_grantingTickets[fromHex(userKey)]
end

function removeGrantingTicket(userKey)
    g_grantingTickets[fromHex(userKey)] = nil
end

function getGrantingTicketOwner(key)
    local gt = g_grantingTickets[fromHex(key)]
    if gt then
        return gt.user
    else
        return nil
    end
end

function makeTicket(grantingTicket, serviceKey)
    --Decrypt the blob.
    local cipher = 
        gcrypt.makeCipher(g_serverKey, g_serverIV)
    local decryptedData = 
        cipher:decrypt(grantingTicket.blob)
    cipher = nil --destroy cipher

    --Parse decrypted data.
    local userTable = parseUserTable(decryptedData)
    if not userTable then
        return nil
    end
    
    --Create ticket for the service.
    local html = string.format([[
    <html>
    <body>
        <p id="user">%s</p>
        <p id="role">%s</p>
        <p id="key">%s</p>
        <p id="iv">%s</p>
        <p id="startTime">%d</p>
        <p id="endTime">%d</p>
        <p id="currentTime">%d</p>
    </body>
    </html>
    ]], userTable.user, 
    userTable.role,
    toHex(userTable.key),
    toHex(userTable.IV),
    userTable.startTime,
    userTable.endTime,
    os.time())
    
    --Encrypt granting ticket with server key 
    cipher = gcrypt.makeCipher(
                serviceKey.key, 
                serviceKey.IV)
    local encryptedData = cipher:encrypt(addPadding(html))
    
    --Create ticket and add it to in memory list.
    local t = {["id"] = #g_tickets + 1, 
               ["blob"] = encryptedData}
    table.insert(g_tickets, t)

    return t
end

function searchTicket(ticketId)
    return g_tickets[tonumber(ticketId)]
end
