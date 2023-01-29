--Based off the PartyBuffs addon by Project Tako
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

addon.name      = 'PartyBuffs';
addon.author    = 'Bag_Town';
addon.version   = '1.4';
addon.desc      = 'Displays a distance and list of icons of current status buffs and ailments next to the party list. Based on Project Tako\'s version.';
addon.link      = 'https://ashitaxi.com/';

require ('common');
local chat          = require('chat');
local d3d           = require('d3d8');
local ffi           = require('ffi');
local fonts         = require('fonts');
local imgui         = require('imgui');
local prims         = require('primitives');
local scaling       = require('scaling');
local settings      = require('settings');
local statusEffects = require('StatusEffects');
local config = require("config");

local C = ffi.C;
local d3d8dev = d3d.get_device();

-- Default Settings
local default_settings = T{
    distance_visible = T{ true },
    distance_scale = T{ 0.67 },    
    status_visible = T{ true },
    status_scale = T{ 0.67, },
    opacity = T{ 1.0 },
    padding = T{ 1 },
    text_padding = T{ 10 },
    size = T{ 32 },

    x = T{ 100 },
    y = T{ 100 },

    distance_font = T{
        color = 0xFFFFFFFF,
        font_family = 'Comic Sans MS',
        font_height = scaling.scale_f(scaling.scale_height(8)),
        bold = true,
        right_justified = true,
        position_x = 1,
        position_y = 1,
        text = '0.0',
        visible = false
    },

    status_effects = statusEffects;
    show_excluded = T{ false },
};

local party_buffs = T{
    preloaded_textures = { },
    sprite = nil,
    rect = ffi.new('RECT', { 0, 0, 32, 32, });
    vec_position = ffi.new('D3DXVECTOR2', { 0, 0, }),
    vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, }),

    subcolor = 0xFFFFFF00,
    maxcolor = 0xFFFF0000,
    subrange = T{ 10.0 },
    maxrange = T{ 22.0 },

    party_member_data = T{
        T{ member = 1, id = nil, statuses = { }, distance = nil, },
        T{ member = 2, id = nil, statuses = { }, distance = nil, },
        T{ member = 3, id = nil, statuses = { }, distance = nil, },
        T{ member = 4, id = nil, statuses = { }, distance = nil, },
        T{ member = 5, id = nil, statuses = { }, distance = nil, },
    },

    settings = settings.load(default_settings),
}; 

--[[   ----------------   ]]--
--[[   HELPER FUNCTIONS   ]]--
--[[   ----------------   ]]--

--[[
* Updates the saved settings to the new values

* @param {s} - The settings table 
--]]
local function update_settings(s)
    if (s ~= nil) then
        party_buffs.settings = s;
    end

    -- Need to cycle through each party member and apply the font change
    party_buffs.party_member_data:each(function (pmd)
        if(pmd.distance ~= nil) then
            pmd.distance:apply(party_buffs.settings.distance_font);
        end
    end);

    settings.save();
end

--[[
* Loads a buff icon texture from the /addons/partybuffs/icons/ folder with the given buff id

* @param {int} - asset number for png file loading 
--]]
local function load_asset_texture(asset)
    if (asset == -1) then return nil; end
    local path = ('%saddons\\%s\\icons\\'):append(type(asset) == 'number' and '%d' or '%s'):append('.png'):fmt(AshitaCore:GetInstallPath(), 'PartyBuffs', asset);
    if (not ashita.fs.exists(path)) then
        return nil;
    end

    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    if (C.D3DXCreateTextureFromFileA(d3d8dev, path, texture_ptr) ~= C.S_OK) then
        return nil;
    end
    return d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texture_ptr[0]));
end

--[[
* Prints the addon help information

* @param {boolean} isError - Flag if this function was invoked due to an error.
--]]
local function print_help(isError)
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
        { '/[ partybuffs | pb ] config', 'Brings up the configuration window.' },
        { '/[ partybuffs | pb ] excluded', 'Toggles whether excluded status icons are displayed or not.' },
        { '/[ partybuffs | pb ] show [ status | distance ]', 'Toggles whether status icons or distance are displayed or not.' },
        { '/[ partybuffs | pb ] help', 'Help and available commands.' },
        { '/[ partybuffs | pb ] subrange [ number ]', 'Specify the sub range distance.' },
        { '/[ partybuffs | pb ] maxrange [ number ]', 'Specify the max range distance.' },
    };

    -- Print the command list.
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);
end

--DEBUGGING Remove later
local function print_settings()
    print("Settings, Distance_Visible: " .. tostring(not not party_buffs.settings.distance_visible[1]));
    print("Settings, Status_Visible: " .. tostring(not not party_buffs.settings.status_visible[1]));
    print("Settings, Opacity: " .. tostring(party_buffs.settings.opacity[1]));
    print("Settings, Size: " .. tostring(party_buffs.settings.size[1]));
    print("Settings, Distance Scale: " .. tostring(party_buffs.settings.distance_scale[1]));
    print("Settings, Status Scale: " .. tostring(party_buffs.settings.status_scale[1]));
    print("Settings, X: " .. tostring(party_buffs.settings.x[1]));
    print("Settings, Y: " .. tostring(party_buffs.settings.y[1]));
    print("Settings, Show_Excluded: " .. tostring(not not party_buffs.settings.show_excluded[1]));
    print("Settings, Editor.isOpen: " .. tostring(not not config.uiSettings.is_open[1]));

    party_buffs.party_member_data:each(function (pmd) 
        print('PMD Member: ' .. tostring(pmd.member));
        print('PMD ID: ' .. tostring(pmd.id));
        for key, value in pairs(pmd.statuses) do
            print('Member: ' .. tostring(pmd.member) .. ' Status ID: ' .. tostring(value));
        end
    end);
end

--[[
* Render the party member distance font text.

* @param {table} party_member_data - Party member data list.
* @param {int} offset - X offset for the rendering.
--]]
local function render_party_distance(party_member_data, offset)
    if(party_buffs.settings.distance_visible[1]) then
        local distance = AshitaCore:GetMemoryManager():GetEntity():GetDistance(AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(party_member_data.member));
       
        -- Change color based on range of the party member
        local text_color = party_buffs.settings.distance_font.color;
        if( math.sqrt(distance) > party_buffs.subrange[1] ) then
            text_color = party_buffs.subcolor;
        end
        if( math.sqrt(distance) > party_buffs.maxrange[1] ) then
            text_color = party_buffs.maxcolor;
        end

        party_member_data.distance.position_x = party_buffs.settings.x[1] - offset;
        party_member_data.distance.position_y = party_buffs.settings.y[1] - ((AshitaCore:GetMemoryManager():GetParty():GetAlliancePartyMemberCount1() - 1 - party_member_data.member) * scaling.scale_height(20));
        party_member_data.distance.color = text_color;
        party_member_data.distance.text = string.format('%.1f', math.sqrt(distance));
        party_member_data.distance.visible = true;
        party_member_data.distance:render();
        
    else
        party_member_data.distance.visible = false;
    end
end

--[[
* Render the party member status effect icons.

* @param {table} party_member_data - Party member data list.
* @param {int} offset - X offset for the rendering.
--]]
local function render_party_sprites(party_member_data, offset) 
    if(party_buffs.settings.status_visible[1]) then
        for key, value in pairs(party_member_data.statuses) do

            party_buffs.settings.opacity[1] = math.clamp(party_buffs.settings.opacity[1], 0.125, 1);
            local color = d3d.D3DCOLOR_ARGB(party_buffs.settings.opacity[1] * 255, 255, 255, 255);

            if(value ~= nil) then
                party_buffs.vec_position.x = party_buffs.settings.x[1] - offset;
                party_buffs.vec_position.y = party_buffs.settings.y[1] - ((AshitaCore:GetMemoryManager():GetParty():GetAlliancePartyMemberCount1() - 1 - party_member_data.member) * scaling.scale_height(20)); 
                party_buffs.vec_scale.x = party_buffs.settings.status_scale[1] * scaling.scaled.w;
                party_buffs.vec_scale.y = party_buffs.settings.status_scale[1] * scaling.scaled.h;

                -- Draw everything if showing exluded items, otherwise see if it's in the excluded list.
                if(party_buffs.settings.show_excluded[1] or party_buffs.settings.status_effects[value].excluded[1] == false) then
                    party_buffs.sprite:Draw(party_buffs.preloaded_textures[value], party_buffs.rect, party_buffs.vec_scale, nil, 0.0, party_buffs.vec_position, color);
                    offset = offset + (party_buffs.settings.status_scale[1] * party_buffs.settings.size[1]) + party_buffs.settings.padding[1];
                end
            end
        end
    end
end

--[[   ------------------------   ]]--
--[[   EVENT REGISTER FUNCTIONS   ]]-- 
--[[   ------------------------   ]]--

--[[
* event: command
* desc: Event called when the addon is processing a command
--]]
ashita.events.register('command', 'command_cb', function(e)
    --Parse the command arguments.
    local args = e.command:args();
    if (#args > 0 and (args[1]:any('/partybuffs') or args[1]:any('/pb'))) then

        e.blocked = true;

        -- Handle: /partybuffs config or /pb config - Toggles the PartyBuffs editor
        if (#args >= 2 and args[2]:any('config')) then
            config.uiSettings.is_open[1] = not config.uiSettings.is_open[1];
            return;
        end

        -- Handle: /partybuffs excluded or /pb excluded - Toggles the excluded status icons.
        if (#args >= 2 and args[2]:any('excluded')) then
            party_buffs.settings.show_excluded[1] = not party_buffs.settings.show_excluded[1];
            if(party_buffs.settings.show_excluded[1]) then
                print(chat.header(addon.name):append(chat.message('Displaying excluded status icons.')));
            else
                print(chat.header(addon.name):append(chat.message('Hiding excluded status icons.')));
            end 
            return;
        end

        -- Handle: /partybuffs config or /pb config - Toggles the status icons. Continue to display distance.
        if (#args >= 2 and args[2]:any('show')) then
            if(#args == 3 and args[3]:any('status')) then
                party_buffs.settings.status_visible[1] = not party_buffs.settings.status_visible[1];
                if(party_buffs.settings.status_visible[1]) then
                    print(chat.header(addon.name):append(chat.message('Displaying status icons.')));
                else
                    print(chat.header(addon.name):append(chat.message('Hiding status icons.')));
                end 
            elseif(#args == 3 and args[3]:any('distance'))  then
                party_buffs.settings.distance_visible[1] = not party_buffs.settings.distance_visible[1];
                if(party_buffs.settings.distance_visible[1]) then
                    print(chat.header(addon.name):append(chat.message('Displaying party members distances.')));
                else
                    print(chat.header(addon.name):append(chat.message('Hiding party members distances.')));
                end 
            else
                print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name .. ' show')));
            end
            return;
        end

        -- Handle: /partybuffs reset OR /pb reset - Resets the current settings.
        if (#args >= 2 and args[2]:any('reset')) then
            settings.reset();
            settings.save();
            print(chat.header(addon.name):append(chat.message('Settings reset to defaults.')));
            return;
        end

        -- Handle: /partybuffs subrange OR /pb subrange - Sets the subrange distance in settings.
        if (#args == 3 and args[2]:any('subrange')) then
            local range = args[3]:number_or();
            party_buffs.subrange[1] = range;
            print(chat.header(addon.name):append(chat.message('Subrange set to: ' .. range)));
            return;
        end

        -- Handle: /partybuffs maxrange OR /pb maxrange - Sets the maxrange distance in settings.
        if (#args >= 2 and args[2]:any('maxrange')) then
            local range = args[3]:number_or();
            party_buffs.maxrange[1] = range;
            print(chat.header(addon.name):append(chat.message('Subrange set to: ' .. range)));
            return;
        end

         -- Handle: /partybuffs reset OR /pb reset - Resets the current settings.
         if (#args >= 2 and args[2]:any('printsettings')) then
            print_settings();
            return;
        end

        -- Unhandled or help message. Print help information.
        print_help(true);
    else
        return;
    end
end);

--[[
* event: d3d_beginscene
* desc : Event called when the Direct3D device is beginning a scene.
--]]
ashita.events.register('d3d_beginscene', 'beginscene_cb', function (isRenderingBackBuffer)
    if (not isRenderingBackBuffer) then return; end
end);   

--[[
* event: d3d_present
* desc: Event called when the addon is being rendered.
--]]

ashita.events.register('d3d_present', 'present_cb', function()
    if (party_buffs.sprite == nil) then
        return;
    end

    local player_zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);

    if (AshitaCore:GetMemoryManager():GetParty():GetAlliancePartyMemberCount1() > 1) then
        party_buffs.sprite:Begin();
        
        party_buffs.party_member_data:each(function (pmd)
            local xoffset = 0;

            if(pmd.id ~= 0 and pmd.id ~= nil) then
                if (player_zone ~= AshitaCore:GetMemoryManager():GetParty():GetMemberZone(pmd.member) or AshitaCore:GetMemoryManager():GetParty():GetMemberIsActive(pmd.member) == 0) then
                    pmd.distance.visible = false;
                else
                    render_party_distance(pmd, xoffset);
                    if(party_buffs.settings.distance_visible[1]) then
                        xoffset = xoffset + (2 * math.ceil((party_buffs.settings.distance_scale[1] * party_buffs.settings.size[1]))) + party_buffs.settings.text_padding[1];
                    end
                    render_party_sprites(pmd, xoffset);
                end
            end

        end);

        party_buffs.sprite:End();
    end

    config.render_editor(party_buffs.settings, party_buffs.party_member_data, party_buffs.subrange, party_buffs.subcolor, party_buffs.maxrange, party_buffs.maxcolor);
    
    if (config.uiSettings.font_changed[1]) then
        update_settings();
        config.uiSettings.font_changed[1] = false;
    end
end);

--[[
* event: load
* desc: First called when our addon is loaded.
--]]
ashita.events.register('load', 'load_cb', function()
    party_buffs.settings.x[1] = scaling.window.w - scaling.scale_width(150);
    party_buffs.settings.y[1] = scaling.window.h - scaling.scale_height(40);

    -- Preload all the textures so not constantly reading from disk.
	for x = 0, 639, 1 do
		party_buffs.preloaded_textures[x] = load_asset_texture(x)
	end

    local sprite_ptr = ffi.new('ID3DXSprite*[1]');
    if (C.D3DXCreateSprite(d3d8dev, sprite_ptr) ~= C.S_OK) then
        error('failed to make sprite obj');
    end
    party_buffs.sprite = d3d.gc_safe_release(ffi.cast('ID3DXSprite*', sprite_ptr[0]));

    -- Create inital party member data.
    party_buffs.party_member_data:each( function(pmd)
        pmd.distance = fonts.new(party_buffs.settings.distance_font);
        local server_id = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(pmd.member);
        if(server_id ~= 0) then
            pmd.id = server_id;
            pmd.distance.visible = true;
        end
    end);
end);

--[[
* event: packet_in
* desc: Called when our addon receives an incoming packet.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function(e)
    -- Zone packet, clean up stored status ids
	if (e.id == 0x0A) then
        party_buffs.party_member_data:each( function(pmd)
            local server_id = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(pmd.member);
            if(server_id ~= 0) then
                pmd.id = server_id;
                pmd.statuses = { };
            end
        end);
        
    -- Party update packet
	elseif (e.id == 0xDD) then
        party_buffs.party_member_data:each( function(pmd)
            -- Party member either added or removed. Reset IDs and pull new data
            pmd.id = 0;
            local server_id = AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(pmd.member);
			if (server_id ~= 0) then
                pmd.id = server_id;
                --pmd.statuses = { }; FIXME IF NEEDED
            end
        end);

    -- Party effects packet
	elseif (e.id == 0x76) then
        for x = 0, 4, 1 do
			local server_id = struct.unpack('I', e.data_modified, x * 0x30 + 0x04 + 1);

            party_buffs.party_member_data:each( function (pmd)
                if( pmd.id == server_id) then
                    pmd.statuses = { };
                    for i = 0, 31, 1 do
                        local mask = bit.band(bit.rshift(struct.unpack('b', e.data_modified, bit.rshift(i, 2) + (x * 0x30 + 0x0C) + 1), 2 * (i % 4)), 3);
                        if (struct.unpack('b', e.data_modified, (x * 0x30 + 0x14) + i + 1) ~= -1 or mask > 0) then
                            local status_id = bit.bor(struct.unpack('B', e.data_modified, (x * 0x30 + 0x14) + i + 1), bit.lshift(mask, 8));
                            if (status_id ~= nil and status_id > 1) then
                                pmd.statuses[i] = status_id;
                            end
                        end
                    end
                end
            end);
		end
    end

    return false;
end);

--[[
* event: packet_out
* desc: Called when our addon receives an outgoing packet.
--]]
ashita.events.register('packet_out', 'packet_out_cb', function(e)
    -- Party Leaving packet, cleanup any IDs so no text/status effects are displayed.
    if (e.id == 0x6F) then
        party_buffs.party_member_data:each( function (pmd)
            pmd.id = 0;
            pmd.distance.visible = false;
        end);
    end

	return false;
end);

--[[
* Registers a callback for the settings to monitor for character switches.
--]]
settings.register('settings', 'settings_update', update_settings);

--[[
* event: unload 
* desc: Called when our addon is unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function()
    update_settings();
    party_buffs.sprite = nil;
    party_buffs.party_member_data:each( function(pmd) 
        pmd.id = nil;
        pmd.statuses = { };
        if (pmd.distance ~= nil) then
            pmd.distance:destroy();
            pmd.distance = nil;
        end
    end);

    party_buffs.preloaded_textures = nil;

    settings.save();
end);