--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local newchat = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function newchat:init()
    newchat.commands = mattata.commands(self.info.username):command('newchat').table
end

function newchat:on_message(message, configuration, language)
    if not mattata.is_global_admin(message.from.id)
    then
        return false
    end
    local input = mattata.input(message.text)
    if not input
    then
        return false
    end
    local link, title = input:match('^(.-) (.-)$')
    if not title
    then
        link = input
        title = link
    end
    if not link
    then
        return mattata.send_reply(
            message,
            'Please specify a link to add to the list shown when /groups is sent. You need to use the following syntax: /newchat <link> [title]. If a title isn\'t given, the link will be used as the title too.'
        )
    elseif not link:match('https?://t%.me/.-$')
    then
        return mattata.send_reply(
            message,
            'The link must begin with "https://t.me/"!'
        )
    end
    local entry = json.encode(
        {
            ['link'] = tostring(link),
            ['title'] = tostring(title)
        }
    )
    local entries = redis:smembers('mattata:configuration:chats')
    for k, v in pairs(entries)
    do
        if not v
        or not json.decode(v).link
        or not json.decode(v).title
        then
            return false
        elseif json.decode(v).link == link
        then
            return mattata.send_reply(
                message,
                'That link already exists in the database, under the name "' .. json.decode(v).title .. '"!'
            )
        end
    end
    redis:sadd(
        'mattata:configuration:chats',
        entry
    )
    return mattata.send_reply(
        message,
        'I have added that link to the list shown when /groups is sent, under the name "' .. title .. '"!'
    )
end

return newchat