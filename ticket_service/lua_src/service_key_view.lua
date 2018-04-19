require("http_common")

function renderServiceKey(serviceKey)
    local output = string.format([[
        <html>
            <body>
                <p id="service_name">%s</p>
                <p id="key">%s</p>
                <p id="IV">%s</p>
            </body>
        </html>
    ]],
    serviceKey.service_name,
    toHex(serviceKey.key),
    toHex(serviceKey.IV))

    return output
end
