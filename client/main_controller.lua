require("main_view")
require("popup_view")

require("client_model")

local fl = require( "fltk4lua" )

local function login_callback(user, pass)
    local wm = require("window_manager")
    
    if user == "" or pass == "" then
        wm.showPopup("Incorrect data!")
        return
    end
    
    if not login(user, pass) then
        wm.showPopup("Login failed!")
        return
    end

    wm.showWindow("services")
end

local function about_callback()
    local wm = require("window_manager")
    wm.showWindow("about")
end

local t = {
    ["login"] = login_callback,
    ["about"] = about_callback
}
return t
