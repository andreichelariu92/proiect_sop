require("client_model")

local function dhcp_callback()
    local wm = require("window_manager")
    
    local dhcpSuccess = createDhcpTicket()
    if not dhcpSuccess  then
        wm.showPopup("Cannot create DHCP ticket")
        return
    end

    wm.showWindow("dhcp")
end

local function back_callback()
    local wm = require ("window_manager")
    wm.showWindow("main")
end

local t = {
    ["dhcp"] = dhcp_callback,
    ["back"] = back_callback
}
return t
