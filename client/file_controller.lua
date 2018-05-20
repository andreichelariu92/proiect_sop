require("client_model")

local function backCallback()
    local wm = require("window_manager")
    wm.showWindow("dhcp")
end

local t = {
    ["back"] = backCallback,
}
return t
