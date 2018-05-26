function renderUser(user)
    if not user then
        return nil
    end

    local html = string.format([[
    <html>
    <body>
        <h1> User:</h1>
        <p id="id">%d</p>
        <p id="name">%s</p>
        <p id="password">%s</p>
    </body>
    </html>
    ]],
    user.id,
    user.name,
    user.password)

    return html
end

function renderService(service)
    if not service then
        return nil
    end

    local html = string.format([[
    <html>
    <body>
        <h1> Service:</h1>
        <p id="id">%d</p>
        <p id="name">%s</p>
        <p id="password">%s</p>
    </body>
    </html>
    ]],
    service.id,
    service.name,
    service.password)
    
    return html
end
