local function create_services_window(fl, controller)
    --Check that the callbacks are valid.
    if type(controller.dhcp) ~= "function" or
       type(controller.back) ~= "function" then
       return nil
    end

    local window = 
            fl.Window( 600, 500, "Single Sign On")
    --Title label
    fl.Box({
        0,
        0, 
        600,
        50, 
        "Available services:"
    })
    
    local function dhcp_callback_dispacher()
        controller.dhcp()
    end
    local login_button = fl.Button({
        200,
        150,
        200,
        50,
        "DHCP",
        callback=dhcp_callback_dispacher
    })

    local function back_callback_dispacher()
        controller.back()
    end
    local about_button = fl.Button({
        200,
        400,
        200,
        50,
        "Back",
        callback=back_callback_dispacher
    })

    
    window:end_group()
    
    return window
end

local t = {
    ["create"] = create_services_window
}
return t
