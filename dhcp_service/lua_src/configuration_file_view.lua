function renderFile(fileBlob)
    if not fileBlob then
        return nil
    end
    
    local html = string.format([[
    <html>
    <body>
        <h1>Content of file:</h1>
        <p id="blob">%s</p>
    </body>
    </html>]],
    fileBlob)
    
    return html
end
