local function backCallback()
    local wm = require("window_manager")
    wm.showWindow("main")
end

local t = {
    ["back"] = backCallback
}
return t
