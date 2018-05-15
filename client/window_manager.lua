local fl = require( "fltk4lua" )

--main window
local main_view = require("main_view")
local main_controller = require("main_controller")
--about window
local about_view = require("about_view")
local about_controller = require("about_controller")

--services window

--DHCP window

--config file window

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

    g_windows = {
        ["main"] = main_window,
        ["about"] = about_window
    }

end

local function run()
    g_windows.main:show()
    g_currentWindow = g_windows.main
    fl.run()
end

local function showWindow(name)
    local w = g_windows[name]
    if w then
        g_currentWindow:hide()
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
