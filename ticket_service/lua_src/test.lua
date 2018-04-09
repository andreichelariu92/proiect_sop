local gcrypt = require("lua_gcrypt")

-- The key should be a string with size=32
local key = gcrypt.generateKey()
assert((type(key) == 'string') and (string.len(key) == 32))

-- The initialization vector should be a string with size=16
local iv = gcrypt.generateIV()
assert((type(iv) == 'string') and (string.len(iv) == 16))

-- Create a cipher with the above key and value
local cipher = gcrypt.makeCipher(key, iv)
assert(cipher)

-- Encrypt a message of the correct size (16)
-- The encrypted and decrypted message should be the same.
local message = "Ana are mere    "
local encryptedMessage = cipher:encrypt(message)
assert(encryptedMessage)

local decryptedMessage = cipher:decrypt(encryptedMessage)
assert(decryptedMessage)

assert(message == decryptedMessage)

-- Encrypt a message of incorrect size
-- There should be an error generated
local success = pcall(function ()
    local badMessage = "Bad message"
    cipher:encrypt(badMessage)
end)
assert(success == false)
print("All tests went OK :)")
