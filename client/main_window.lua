local function buttonCallback(button, user_data)
    print(user_data)
end

local fl = require( "fltk4lua" )
local window = fl.Window( 600, 500, "Signle Sign On")

fl.Box({
    0,--x
    0,--y 
    600,--width
    50,--height 
    "Single Sign On"--Text
})

fl.Input({
    200,
    100,
    200,
    50,
    "User name"
})

fl.Input({
    200,
    200,
    200,
    50,
    "Password",
    type="FL_SECRET_INPUT"
})

fl.Button({
    200,
    300,
    200,
    50,
    "Log in",
    callback=buttonCallback
})

fl.Button({
    200,
    400,
    200,
    50,
    "About",
    callback=buttonCallback
})

window:end_group()
window:show()
fl.run()
