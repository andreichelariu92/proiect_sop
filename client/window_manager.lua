local fl = require( "fltk4lua" )

--main window
local main_view = require("main_view")
local main_controller = require("main_controller")
--about window
local about_view = require("about_view")
local about_controller = require("about_controller")
--services window
local services_view = require("services_view")
local services_controller = require("services_controller")
--DHCP window
local dhcp_view = require("dhcp_view")
local dhcp_controller = require("dhcp_controller")
--config file window
local file_view = require("file_view")
local file_controller = require("file_controller")

--List of all windows
local g_windows = nil
local g_currentWindow = nil

local function init()
    local main_window = main_view.create(fl, 
                            main_controller)
    if not main_window then
        print("Error creating main window")
        return
    end

    local about_window = about_view.create(fl, about_controller)
    if not about_window then
        print("Error creating about window")
        return
    end
    
    local services_window = services_view.create(fl, services_controller)
    if not services_window then
        print("Error creating services window")
        return
    end
    
    local dhcp_window = dhcp_view.create(fl, dhcp_controller)
    if not dhcp_window then
        print("Error creating dhcp window")
        return
    end
    
    local file_window = file_view.create(fl, file_controller)
    if not file_window then
        print("error creating file window")
        return
    end
    
    g_windows = {
        ["main"] = main_window,
        ["about"] = about_window,
        ["services"] = services_window,
        ["dhcp"] = dhcp_window,
        ["file"] = file_window
    }

end

local function run()
    g_windows.main:show()
    g_currentWindow = g_windows.main
    fl.run()
end

local function showWindow(name, params)
    local w = g_windows[name]
    if w then
        g_currentWindow:hide()
        if name == "file" then
            file_view.setContent(params)
        end
        w:show()
        g_currentWindow = w
    end
end

local function showPopup(title)
    local p = create_popup(fl, title)
    if p then
        p:show()
    end
end

local t = {
    ["init"] = init, 
    ["showWindow"] = showWindow,
    ["run"] = run,
    ["showPopup"] = showPopup
}
return t
