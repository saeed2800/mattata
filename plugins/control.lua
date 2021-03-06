--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local control = {}
local mattata = require('mattata')

function control:init()
    control.commands = mattata.commands(self.info.username):command('reload')
    :command('reboot')
    :command('icanhasreboot').table
end

function control:on_message(message, configuration, language)
    if not mattata.is_global_admin(message.from.id)
    then
        return mattata.send_reply(
            message,
            language['control']['1']
        )
    end
    for p, _ in pairs(package.loaded)
    do
        if p:match('^plugins%.')
        then
            package.loaded[p] = nil
        end
    end
    package.loaded['mattata'] = nil
    package.loaded['configuration'] = nil
    for k, v in pairs(configuration)
    do
        configuration[k] = v
    end
    mattata.init(
        self,
        configuration
    )
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['control']['2'],
            self.info.name
        )
    )
end

return control