local g_user_input = nil

local function create_file_window(fl, controller)
    --Check that the callbacks are valid.
    if type(controller.back) ~= "function" then
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
        "Configuration file content:"
    })
    
    g_user_input = fl.Input({
        0,
        75,
        600,
        350,
        value = "",
        type = "FL_MULTILINE_OUTPUT_WRAP"
    })


    local function back_callback_dispacher()
        controller.back()
    end
    local about_button = fl.Button({
        200,
        430,
        200,
        50,
        "Back",
        callback=back_callback_dispacher
    })

    
    window:end_group()
    return window
end

local function setFileContent(text)
    g_user_input.value = text
end

local t = {
    ["create"] = create_file_window,
    ["setContent"] = setFileContent
}
return t
