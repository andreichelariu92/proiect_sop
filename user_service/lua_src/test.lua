require("user_model")
require("user_view")

local u = searchUser("andreichelariu92")
if u then
    print(renderUser(u))
end

local s = searchService("leService")
if s then
    print(renderService(s))
end
