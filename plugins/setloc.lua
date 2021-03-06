--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setloc = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function setloc:init()
    setloc.commands = mattata.commands(
        self.info.username
    ):command('setloc').table
    setloc.help = [[/setloc <location> - Sets your location to the given value.]]
end

function setloc.check_loc(location)
    local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(location))
    if res ~= 200 then
        return false, configuration.errors.connection
    end
    local jdat = json.decode(jstr)
    if jdat.status == 'ZERO_RESULTS' then
        return false, configuration.errors.results
    end
    return true, jdat.results[1].geometry.location.lat .. ':' .. jdat.results[1].geometry.location.lng .. ':' .. jdat.results[1].formatted_address
end

function setloc.set_loc(user, location)
    local validate, res = setloc.check_loc(location)
    if not validate then
        return res
    end
    local latitude, longitude, address = res:match('^(.-):(.-):(.-)$')
    local user_loc = json.encode(
        {
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['address'] = address
        }
    )
    local hash = mattata.get_user_redis_hash(
        user,
        'location'
    )
    if hash then
        redis:hset(
            hash,
            'location',
            user_loc
        )
        return 'Your location has been updated to: ' .. address .. '\nYou can now use commands such as /weather and /location, without needing to specify a location - your location will be used by default. Giving a different location as the command argument will override this.'
    end
end

function setloc.get_loc(user)
    local hash = mattata.get_user_redis_hash(
        user,
        'location'
    )
    if hash then
        local location = redis:hget(
            hash,
            'location'
        )
        if not location or location == 'false' or location == nil then
            return false
        else
            return location
        end
    end
end

function setloc:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        local location = setloc.get_loc(message.from)
        if not location then
            return mattata.send_reply(
                message,
                'You don\'t have a location set. Use /setloc <location> to set one.'
            )
        end
        return mattata.send_reply(
            message,
            'Your location is currently set to: ' .. json.decode(location).address
        )
    end
    return mattata.send_message(
        message.chat.id,
        setloc.set_loc(
            message.from,
            input
        )
    )
end

return setloc