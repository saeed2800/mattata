--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local identicon = {}
local mattata = require('mattata')
local url = require('socket.url')

function identicon:init()
    identicon.commands = mattata.commands(self.info.username)
    :command('identicon')
    :command('icon').table
    identicon.help = '/identicon <text> - Generates an identicon from the given string of text. Alias: /icon.'
end

function identicon:on_message(message)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            identicon.help
        )
    end
    return mattata.send_photo(
        message.chat.id,
        'http://identicon.rmhdev.net/' .. url.escape(input) .. '.png'
    )
end

return identicon