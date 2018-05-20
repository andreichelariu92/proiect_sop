require("client_model")

function view_file_callback()
    local wm = require("window_manager")
    local viewSuccess = readConfigurationFile()
    if not viewSuccess then
        wm.showPopup("Cannot read config file!")
        return
    end

    wm.showWindow("file", getFileContent())
end

function back_callback()
    local wm = require("window_manager")
    wm.showWindow("services")
end

local t = {
    ["viewFile"] = view_file_callback,
    ["back"] = back_callback
}
return t
