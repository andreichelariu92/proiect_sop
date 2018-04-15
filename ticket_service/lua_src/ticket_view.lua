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
