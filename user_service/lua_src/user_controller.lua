require("http_common")
require("user_model")
require("user_view")

local function getUser(stream, headers)
    --Extract user name from URI.
    local pattern = "/UserService/Users/(%w+)"
    local userName = getKeyFromHeaders(headers,
                        pattern)
    if not userName then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get the user from the database
    local user = searchUser(userName)
    if not user then
        setHeaders(stream, NOT_FOUND)
    end

    --Render user and send it to le client.
    local html = renderUser(user)
    if not html then
        setHeaders(stream, SERVER_ERROR)
    end

    --Send the representation to the client.
    setHeaders(stream, SUCCESS)
    stream:write_chunk(html, true)
end

local t = {
    ["get"] = getUser,
    ["pattern"] = "/userservice/users/"
}
return t
