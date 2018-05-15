function create_popup(fl, title)
    local window = fl.Window(400, 250)
    local function ok_callback()
        window:hide()
    end
    
    fl.Box({
        0,
        0,
        400,
        100,
        title
    })
    
    fl.Button({
        150,
        150,
        100,
        50,
        "OK",
        callback = ok_callback
    })
    
    window:end_group()

    return window
end
