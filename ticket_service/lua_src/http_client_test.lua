local http_request = require("http.request")
local http_tls = require("http.tls")
local context = http_tls:new_client_context()
local openssl_ctx = require "openssl.ssl.context"

context:setVerify(openssl_ctx.VERIFY_NONE)

local request = http_request.new_from_uri("http://localhost:8080/TicketService/GrantingTickets")
request.ctx = context
request.tls = true
request.headers:upsert(":method", "POST")
request.headers:append("content-type", "application/x-www-form-urlencoded")
request:set_body("user=andreichelariu&pass=sex")

local headers, stream =request:go(100)
print("Headers ", headers, "stream ", stream)
if headers then
    for k, v in headers:each() do
        print(k, v)
    end
end
