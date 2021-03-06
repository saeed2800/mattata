--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local tempban = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function tempban:init()
    tempban.commands = mattata.commands(self.info.username):command('tempban').table
    tempban.help = '/tempban [user]  - Temporarily ban a user from the chat. The user may be specified by username, ID or by replying to one of their messages.'
end

function tempban.get_keyboard(chat_id, user_id)
    return mattata.inline_keyboard()
    :row(
        mattata.row()
        :callback_data_button(
            '1 minute',
            'tempban:' .. chat_id .. ':' .. user_id .. ':60:1 minute'
        )
        :callback_data_button(
            '5 minutes',
            'tempban:' .. chat_id .. ':' .. user_id .. ':300:5 minutes'
        )
        :callback_data_button(
            '15 minutes',
            'tempban:' .. chat_id .. ':' .. user_id .. ':900:15 minutes'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            '30 minutes',
            'tempban:' .. chat_id .. ':' .. user_id .. ':1800:30 minutes'
        )
        :callback_data_button(
            '1 hour',
            'tempban:' .. chat_id .. ':' .. user_id .. ':3600:1 hour'
        )
        :callback_data_button(
            '6 hours',
            'tempban:' .. chat_id .. ':' .. user_id .. ':21600:6 hours'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            '12 hours',
            'tempban:' .. chat_id .. ':' .. user_id .. ':43200:12 hours'
        )
        :callback_data_button(
            '1 day',
            'tempban:' .. chat_id .. ':' .. user_id .. ':86400:1 day'
        )
        :callback_data_button(
            '1 week',
            'tempban:' .. chat_id .. ':' .. user_id .. ':604800:1 week'
        )
    )
end

function tempban:on_callback_query(callback_query, message, configuration, language)
    if not callback_query.data:match('^%-?%d+:%d+:%d%d?%d?%d?%d?%d?:.-$')
    then
        return mattata.answer_callback_query(callback_query.id)
    end
    local chat_id, user_id, duration, formatted_duration = callback_query.data:match('^(%-?%d+):(%d+):(%d%d?%d?%d?%d?%d?):(.-)$')
    if not mattata.is_group_admin(
        chat_id,
        callback_query.from.id
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'You\'re not an administrator in this chat!',
            true
        )
    elseif not mattata.is_group_admin(
        chat_id,
        self.info.id,
        true
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'I need to have administrative permissions to temp-ban this user!',
            true
        )
    elseif mattata.is_group_admin(
        chat_id,
        user_id
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'That user appears to have been granted administrative permissions since the keyboard was sent!',
            true
        )
    end
    local success = mattata.ban_chat_member(
        chat_id,
        user_id,
        os.time() + tonumber(duration)
    )
    local user = mattata.get_user(user_id)
    user = user.result
    if not success
    then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'I could not ban <b>' .. mattata.escape_html(user.first_name) .. '</b>!',
            'html'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        'I have successfully temp-banned <b>' .. mattata.escape_html(user.first_name) .. '</b> for ' .. formatted_duration .. '!',
        'html'
    )
end

function tempban:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        self.info.id,
        true
    )
    then
        return mattata.send_reply(
            message,
            'I need to have administrative permissions to temp-ban this user!'
        )
    end
    local input = mattata.input(message.text)
    local user = input
    if not input
    or message.reply
    then
        if not message.reply
        then
            return mattata.send_reply(
                message,
                tempban.help
            )
        end
        user = message.reply.from
    else
        if tonumber(user) == nil
        and not user:match('^@')
        then
            user = '@' .. user
        end
        user = mattata.get_user(user)
        if user
        then
            user = user.result
        end
    end
    if type(user) ~= 'table'
    then
        return mattata.send_reply(
            message,
            'Sorry, but I don\'t recognise this user! If you\'d like to teach me who they are, please forward a message from them to me.'
        )
    end
    user = mattata.get_chat_member(
        message.chat.id,
        user.id
    )
    if not user
    or type(user) ~= 'table'
    or not user.result
    or not user.result.user
    or not user.result.status
    or user.result.status == 'kicked'
    or user.result.status == 'left'
    then
        return mattata.send_reply(
            message,
            'Are you sure you specified the correct user? They do not appear to be a member of this chat.'
        )
    end
    user = user.result.user
    if mattata.is_group_admin(
        message.chat.id,
        user.id
    )
    then
        return mattata.send_reply(
            message,
            'This user appears to be an administrator of this chat. I\'m sorry, but I cannot temp-ban administrators!'
        )
    end
    return mattata.send_message(
        message.chat.id,
        'Please select the duration you would like to temp-ban <b>' .. mattata.escape_html(user.first_name) .. '</b> for:',
        'html',
        true,
        false,
        nil,
        tempban.get_keyboard(
            message.chat.id,
            user.id
        )
    )
end

return tempban