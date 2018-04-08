local gcrypt = require("lua_gcrypt")
local key = gcrypt.generateKey()
print(key, string.len(key))

local iv = gcrypt.generateIV()
print(iv, string.len(iv))

