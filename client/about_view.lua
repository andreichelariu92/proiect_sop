local function create_about_window(fl, controller)
    --Check that the callbacks are valid.\
    if type(controller.back) ~= "function" then
        return nil
    end

    local window = 
            fl.Window( 600, 500, "Single Sign On")
    fl.Box({
        0,
        0, 
        600,
        50, 
        [[This is a project for Service Oriented Programming.]]
    })
    fl.Box({
        0,
        100, 
        600,
        50, 
        [[The project implements a single sign on system using web services.]]
    })
    fl.Box({
        0,
        200, 
        600,
        50, 
        [[Made by: Chelariu Andrei and Meleca Vasile.]]
    })

    local function back_callback_dispacher()
        controller.back()
    end
    fl.Button({
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
["create"] = create_about_window
}
return t
