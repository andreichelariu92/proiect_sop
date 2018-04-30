function renderGrantingTicket(gt)
    local html = string.format([[
    <html>
    <body>
        <h1>Granting ticket</h1>
        <p id="key">%s</p>
        <p id="iv">%s</p>
        <p id="blob">%s</p>
	<p id="owner">%s</p>
    </body>
    </html>]],
    toHex(gt.key),
    toHex(gt.IV),
    toHex(gt.blob),
    gt.user)

    return html
end

function renderTicket(ticket)
    local html = string.format([[
    <html>
    <body>
        <h1>Ticket</h1>
        <p id="id">%d</p>
        <p id="blob">%s</p>
    </body>
    </html>]],
    ticket.id,
    toHex(ticket.blob))

    return html
end
