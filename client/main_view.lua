local function create_main_window(fl, controller)
    --Check that the callbacks are valid.
    if type(controller.login) ~= "function" or
       type(controller.about) ~= "function" then
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
        "Single Sign On"
    })
    
    local user_input = fl.Input({
        200,
        100,
        200,
        50,
        "User name"
    })

    local password_input = fl.Input({
        200,
        200,
        200,
        50,
        "Password",
        type="FL_SECRET_INPUT",
        callback=inputCallback
    })

    local function login_callback_dispacher()
        controller.login(user_input.value,
            password_input.value)
    end
    local login_button = fl.Button({
        200,
        300,
        200,
        50,
        "Log in",
        callback=login_callback_dispacher
    })

    local function about_callback_dispacher()
        controller.about()
    end
    local about_button = fl.Button({
        200,
        400,
        200,
        50,
        "About",
        callback=about_callback_dispacher
    })

    
    window:end_group()
    
    return window
end

local t = {
    ["create"] = create_main_window
}
return t
