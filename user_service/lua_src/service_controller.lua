require("http_common")
require("user_model")
require("user_view")

local function getService(stream, headers)
    --Extract service name from URI.
    local pattern = "/UserService/Services/(%w+)"
    local serviceName = getKeyFromHeaders(headers,
                        pattern)
    if not serviceName then
        setHeaders(stream, BAD_REQUEST)
    end

    --Get the service from the database
    local service = searchService(serviceName)
    if not service then
        setHeaders(stream, NOT_FOUND)
    end

    --Render service and send it to le client.
    local html = renderService(service)
    if not html then
        setHeaders(stream, SERVER_ERROR)
    end

    --Send the representation to the client.
    setHeaders(stream, SUCCESS)
    stream:write_chunk(html, true)
end

local t = {
    ["get"] = getService,
    ["pattern"] = "/userservice/services/"
}
return t
