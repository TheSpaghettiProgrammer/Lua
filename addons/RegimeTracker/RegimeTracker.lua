--[[
RegimeTracker - Final Fantasy XI Addon
Tracks regime progress by monitoring mob deaths and checking mob families

Copyright © 2024
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of RegimeTracker nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'RegimeTracker'
_addon.author = 'Your Name'
_addon.version = '1.0.0'
_addon.commands = {'regime', 'rt'}

config = require('config')
require('logger')
require('sqlite3')

-- Default settings
defaults = {}
defaults.enabled = true
defaults.auto_track = true
defaults.show_progress = true
defaults.chat_mode = 'echo' -- echo, say, party, linkshell, etc.
defaults.regime_data = {}

-- Load settings
settings = config.load(defaults)

-- Global variables
local db = nil
local current_regime = nil
local regime_progress = 0
local regime_total = 0
local last_killed_mob = nil

-- Initialize the addon
windower.register_event('load', function()
    log('RegimeTracker loaded!')
    
    -- Try to open the InfoBar database
    local infobar_path = windower.addon_path..'/../InfoBar/database.db'
    if windower.file_exists(infobar_path) then
        db = sqlite3.open(infobar_path)
        log('Connected to InfoBar database')
    else
        log('Warning: InfoBar database not found. Regime tracking will be limited.')
    end
    
    -- Load regime data if available
    load_regime_data()
end)

-- Cleanup on unload
windower.register_event('unload', function()
    if db and db:isopen() then
        db:close()
    end
    log('RegimeTracker unloaded')
end)

-- Handle addon commands
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = {...}
    
    if command == 'help' or command == 'h' then
        show_help()
    elseif command == 'status' or command == 's' then
        show_status()
    elseif command == 'clear' or command == 'c' then
        clear_regime()
    elseif command == 'toggle' or command == 't' then
        settings.enabled = not settings.enabled
        config.save(settings)
        log('RegimeTracker ' .. (settings.enabled and 'enabled' or 'disabled'))
    elseif command == 'reload' then
        windower.send_command('lua reload RegimeTracker')
    elseif command == 'unload' then
        windower.send_command('lua unload RegimeTracker')
    else
        log('Unknown command. Use //regime help for available commands.')
    end
end)

-- Monitor mob deaths
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if not settings.enabled then return end
    
    -- Check for mob death (packet 0x29)
    if id == 0x29 then
        local mob_id = original:unpack('I', 0x04 + 1)
        local mob_index = original:unpack('I', 0x08 + 1)
        
        -- Get the mob that was killed
        local killed_mob = windower.ffxi.get_mob_by_id(mob_id)
        if killed_mob and killed_mob.index == mob_index then
            last_killed_mob = killed_mob
            log('Last mob killed: ' .. killed_mob.name)
        end
    end
end)

-- Monitor chat for regime progress messages
windower.register_event('incoming text', function(original, modified, mode)
    if not settings.enabled then return end
    
    -- Look for regime progress messages
    local progress_pattern = "You defeated a designated target%. %(Progress: (%d+)/(%d+)%)"
    local current_progress, total_targets = modified:match(progress_pattern)
    
    if current_progress and total_targets then
        current_progress = tonumber(current_progress)
        total_targets = tonumber(total_targets)
        
        if current_progress and total_targets then
            -- Auto-detect regime if we don't have one set
            if not current_regime then
                -- Try to determine family from last killed mob
                if last_killed_mob then
                    local mob_family = get_mob_family(last_killed_mob.name, windower.ffxi.get_info().zone)
                    if mob_family then
                        log('Auto-detecting regime: ' .. mob_family .. ' (' .. total_targets .. ' targets)')
                        set_regime(mob_family, total_targets)
                        regime_progress = current_progress
                    else
                        log('Auto-detecting regime progress: ' .. current_progress .. '/' .. total_targets .. ' (family unknown)')
                        -- Set a temporary regime with unknown family
                        set_regime("Unknown", total_targets)
                        regime_progress = current_progress
                    end
                else
                    log('Auto-detecting regime progress: ' .. current_progress .. '/' .. total_targets .. ' (no mob info)')
                    -- Set a temporary regime with unknown family
                    set_regime("Unknown", total_targets)
                    regime_progress = current_progress
                end
            else
                -- Update existing regime progress
                regime_progress = current_progress
                log('Regime progress updated: ' .. regime_progress .. '/' .. regime_total)
            end
            
            -- Check if regime is complete
            if regime_progress >= regime_total then
                regime_complete()
            else
                -- Save progress
                save_regime_data()
            end
        end
    end
    
    -- Look for regime completion messages
    local completion_pattern = "Regime complete! You have defeated (%d+) (.+) targets%."
    local total_killed, family_name = modified:match(completion_pattern)
    
    if total_killed and family_name then
        total_killed = tonumber(total_killed)
        
        if total_killed then
            log('Regime completion detected: ' .. total_killed .. ' ' .. family_name .. ' targets')
            if current_regime then
                regime_complete()
            else
                log('Regime completed but no active regime was being tracked')
            end
        end
    end
    
    -- Look for regime start messages (when player selects from grounds tome)
    local start_pattern = "You have selected the regime: (.+) %((%d+) targets%)"
    local family_name, target_count = modified:match(start_pattern)
    
    if family_name and target_count then
        target_count = tonumber(target_count)
        
        if target_count then
            log('New regime selected: ' .. family_name .. ' (' .. target_count .. ' targets)')
            set_regime(family_name, target_count)
        end
    end
end)



-- Get mob family from database
function get_mob_family(mob_name, zone_name)
    if not db or not db:isopen() then return nil end
    
    local query = string.format('SELECT family FROM "monster" WHERE name = "%s" AND zone = "%s"', mob_name, zone_name)
    
    for family in db:urows(query) do
        return family
    end
    
    return nil
end

-- Set a new regime
function set_regime(family, total)
    current_regime = {
        family = family,
        total = total
    }
    regime_progress = 0
    regime_total = total
    
    log('New regime set: ' .. family .. ' (' .. total .. ' targets)')
    
    -- Save regime data
    save_regime_data()
end

-- Clear current regime
function clear_regime()
    current_regime = nil
    regime_progress = 0
    regime_total = 0
    
    log('Regime cleared')
    
    -- Save regime data
    save_regime_data()
end

-- Handle regime completion
function regime_complete()
    local message = string.format("Regime complete! You have defeated %d %s targets.", regime_total, current_regime.family)
    send_message(message)
    
    -- Clear the completed regime
    clear_regime()
end

-- Send message to chat
function send_message(message)
    if settings.chat_mode == 'echo' then
        windower.add_to_chat(8, '[RegimeTracker] ' .. message)
    else
        windower.send_command('input /' .. settings.chat_mode .. ' ' .. message)
    end
end

-- Save regime data to settings
function save_regime_data()
    if current_regime then
        settings.regime_data = {
            family = current_regime.family,
            total = regime_total,
            progress = regime_progress
        }
    else
        settings.regime_data = {}
    end
    
    config.save(settings)
end

-- Load regime data from settings
function load_regime_data()
    if settings.regime_data and settings.regime_data.family then
        current_regime = {
            family = settings.regime_data.family,
            total = settings.regime_data.total
        }
        regime_progress = settings.regime_data.progress or 0
        regime_total = settings.regime_data.total or 0
        
        if regime_progress > 0 then
            log('Loaded regime: ' .. current_regime.family .. ' (Progress: ' .. regime_progress .. '/' .. regime_total .. ')')
        end
    end
end

-- Show help information
function show_help()
    log('=== RegimeTracker Commands ===')
    log('//regime help - Show this help')
    log('//regime status - Show current regime status')
    log('//regime clear - Clear current regime')
    log('//regime toggle - Enable/disable tracking')
    log('//regime reload - Reload the addon')
    log('//regime unload - Unload the addon')
    log('')
    log('Note: Regimes are automatically detected from chat messages')
    log('No manual setup required!')
end

-- Show current status
function show_status()
    if current_regime then
        log('=== Current Regime Status ===')
        log('Family: ' .. current_regime.family)
        log('Progress: ' .. regime_progress .. '/' .. regime_total)
        if regime_progress > 0 then
            local percentage = math.floor((regime_progress / regime_total) * 100)
            log('Completion: ' .. percentage .. '%')
        end
        if last_killed_mob then
            log('Last killed: ' .. last_killed_mob.name)
        end
        log('Status: ' .. (regime_progress >= regime_total and 'COMPLETE!' or 'In Progress'))
    else
        log('No active regime detected')
        log('Kill a mob and wait for regime progress message to auto-detect')
    end
    log('Tracking: ' .. (settings.enabled and 'enabled' or 'disabled'))
end



-- Log function
function log(message)
    windower.add_to_chat(8, '[RegimeTracker] ' .. message)
end
