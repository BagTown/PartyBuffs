require ("common");

local ffi   = require('ffi');
local imgui = require("imgui");

local config = {}
config.uiSettings = {
    is_open = { false },
    font_changed = { false },
}

local Magic = {
    white_magic_buffs_ids = T{39, 102, 286, 109, 101, 100, 108, 111, 107, 110, 106, 103, 104, 112, 105, 36, 70, 33, 580, 69, 171, 116, 40, 43, 170, 42, 539, 113, 41, 71, 37, },
    white_magic_debuffs_ids = T{21, 30, 11, 14, 17, 9, 20, 134, 8, 15, 156, 29, 4, 566, 31, 6, 13, 565, },
    black_magic_buffs_ids = T{34, 606, 573, 605, 607, 35, 38, },
    black_magic_debuffs_ids = T{135, 5, 128, 130, 133, 488, 487, 129, 18, 7, 540, 3, 131, 132, 2, 19, 10, 12, 567, },
    song_ids = T{213, 202, 196, 207, 216, 221, 194, 215, 205, 211, 210, 204, 218, 193, 199, 201, 214, 219, 197, 198, 223, 206, 195, 203, 200, 192, 212, 209, 222, 208, 220, 217, },
    ninjutsu_ids = T{66, 444, 445, 446, 471, },
    summoning_ids = T{577, 422, 430, 458, 429, 425, 423, 428, 604, 283, 427, 154, 424, 426, },
    dice_roll_ids = T{335, 338, 318, 333, 330, 331, 317, 319, 337, 326, 332, 328, 323, 324, 310, 316, 312, 320, 325, 336, 311, 339, 322, 327, 315, 600, 321, 329, 334, 314, 313, },
}

local Jobs = { 
    war = T{58, 56, 460, 490, 57, 44, 158, 435, 405, 68, 340, },
    mnk = T{445, 61, 60, 59, 406, 341, 46, 461, 491, 436, },
    whm = T{418, 417, 492, 275, 453, 459, 78, 477, },
    blm = T{598, 79, 437, 47, 229, 493, },
    rdm = T{48, 419, 96, 279, 95, 278, 94, 277, 97, 280, 98, 281, 99, 282, 265, 581, 597, 541, 454, 230, 494, },
    thf = T{342, 462, 343, 76, 49, 65, 87, },
    pld = T{114, 438, 274, 344, 74, 496, 50, 621, 478, 623, 403, 62, 463, },
    drk = T{75, 464, 51, 599, 345, 346, 173, 288, 64, 439, 479, 480, 497, 63, },
    bst = T{349, 456, 498, },
    brd = T{499, 231, 347, 409, 52, 455, 348, },
    rng = T{73, 77, 482, 433, 53, 351, 628, 500, 72, 350, 115, 371, },
    sam = T{483, 465, 353, 54, 354, 408, 440, 67, 117, 501, },
    nin = T{441, 421, 484, 502, 352, 420, },
    drg = T{118, 466, 503, 619, 126, },
    smn = T{583, 504, 55, 431, },
    blu = T{163, 164, 165, 355, 356, 457, 485, 505, },
    cor = T{309, 601, 308, 357, 467, },
    pup = T{307, 303, 300, 301, 306, 166, 299, 304, 305, 302, },
    dnc = T{379, 369, 448, 449, 450, 451, 452, 375, 443, 582, 378, 368, 411, 588, 381, 382, 383, 384, 385, 507, 380, 370, 386, 387, 388, 389, 390, 442, 410, 391, 
            392, 393, 394, 395, 468, 472, 376, 396, 397, 398, 399, 400, },
    sch = T{366, 402, 401, 363, 412, 184, 595, 362, 359, 365, 228, 416, 415, 178, 589, 413, 179, 590, 186, 470, 23, 407, 358, 367, 361, 360, 469, 183, 594, 364, 
            181, 592, 187, 188, 377, 182, 593, 414, 185, 596, 180, 591, },
    geo = T{569, 513, 517, 612, 518, 516, 584, 515, 519, 508, },
    run = T{570, 522, 534, 525, 568, 536, 524, 523, 537, 529, 509, 538, 533, 571, 527, 532, 526, 530, 528, 535, 531, },
}

local Other_statuses = T {
    232, 481, 90, 553, 146, 561, 489, 273, 270, 271, 272, 83, 122, 545, 139, 242, 267, 16, 151, 616, 287, 91, 549, 147, 557, 234, 233, 572, 620, 
    254, 257, 241, 615, 86, 125, 548, 142, 239, 579, 266, 276, 243, 127, 585, 486, 298, 586, 153, 263, 249, 93, 550, 149, 558, 81, 120, 543, 137, 
    576, 250, 284, 603, 618, 162, 177, 259, 289, 291, 476, 510, 92, 554, 148, 562, 574, 235, 578, 32, 251, 575, 238, 622, 631, 258, 261, 168, 84, 
    123, 546, 140, 172, 22, 512, 0, 240, 143, 269, 555, 174, 563, 190, 551, 175, 559, 191, 552, 167, 560, 556, 611, 404, 564, 152, 88, 144, 89, 145, 
    189, 155, 85, 124, 547, 141, 627, 629, 252, 473, 447, 432, 613, 295, 610, 609, 296, 293, 297, 626, 294, 608, 260, 262, 264, 159, 292, 150, 169, 
    160, 474, 176, 511, 617, 256, 268, 253, 625, 157, 237, 161, 224, 225, 226, 24, 25, 26, 27, 227, 80, 119, 542, 136, 290, 630, 28, 587, 434, 614, 
    285, 82, 121, 544, 138, 475, 602, 1, 624, 236 
}

local function cflip(c)
    local r, b = c[3], c[1];
    c[1] = r;
    c[3] = b;
    return c;
end

config.render_editor = function(settings, party_member_data, subrange, subcolor, maxrange, maxcolor)
    if (not config.uiSettings.is_open[1]) then
        return;
    end

    imgui.SetNextWindowSize({ 800, 700 }, ImGuiCond_FirstUseEver);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 10, 10 });
    imgui.PushStyleColor(ImGuiCol_Text, { 1.0, 1.0, 1.0, 1.0 });

    if (imgui.Begin('PartyBuffs', config.uiSettings.is_open, bit.bor(ImGuiWindowFlags_NoSavedSettings))) then
        if (imgui.BeginTabBar('##pb_tabbar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
            if (imgui.BeginTabItem('Main Settings', nil)) then
                imgui.BeginGroup();
                    imgui.TextColored({ 1.0, 0.65, 0.26, 1.0 }, 'Status Icons');
                    imgui.BeginChild('status_icons', { 0, 140, }, true);  

                        imgui.Checkbox('Visible', settings.status_visible);
                        imgui.ShowHelp('Toggles if status icons are displayed or not.');
                        imgui.SliderFloat('Opacity', settings.opacity, 0.125, 1.0, '%.3f');
                        imgui.ShowHelp('The opacity of the status icons.');
                        imgui.DragFloat('Scaled Icon Size', settings.status_scale, 0.1, 0.1, 3.0, '%.2f');
                        imgui.ShowHelp('The size of the status icons.\n\nClick and drag to change the value.\nOr double-click to edit directly.');
                        local pad = { settings.padding[1] } 
                        if (imgui.InputInt('Padding', pad)) then
                            settings.padding[1] = pad[1];
                        end
                        imgui.ShowHelp('The pixel padding between status icons');
                        local icon_size = { settings.size[1] } 
                        if (imgui.InputInt('Image Pixel Size', icon_size)) then
                            settings.size[1] = icon_size[1];
                        end
                        imgui.ShowHelp('The pixel width of the status icon images used. (Assuming square icon images)');

                    imgui.EndChild();
                imgui.EndGroup();
                imgui.BeginGroup();
                    imgui.TextColored({ 1.0, 0.65, 0.26, 1.0 }, 'Distance Text');
                    imgui.BeginChild('distance_text', { 0, 210, }, true); 

                        local need_font_update = false;

                        imgui.Checkbox('Visible', settings.distance_visible);
                        imgui.ShowHelp('Toggles if distance to party members text is displayed or not.');
                        local font_h = { settings.distance_font.font_height };
                        if (imgui.InputInt('Font Height', font_h)) then
                            settings.distance_font.font_height = font_h[1];
                            need_font_update = true;
                        end
                        imgui.ShowHelp('The height size of the distance text.');
                        local tpad = { settings.text_padding[1] } 
                        if (imgui.InputInt('Padding', tpad)) then
                            settings.text_padding[1] = tpad[1];
                        end
                        imgui.ShowHelp('The pixel padding between the text and icons');
                        if(imgui.Checkbox('Bold', { settings.distance_font.bold })) then
                            settings.distance_font.bold = not settings.distance_font.bold;
                            need_font_update = true;
                        end
                        imgui.ShowHelp('Toggles if distance to party members text is bolded or not.');
                        if(imgui.Checkbox('Italic', { settings.distance_font.italic })) then
                            settings.distance_font.italic = not settings.distance_font.italic;
                            need_font_update = true;
                        end
                        imgui.ShowHelp('Toggles if distance to party members text is italics or not.');
                        
                        local c = cflip({ imgui.ColorConvertU32ToFloat4(settings.distance_font.color) });
                        if (imgui.ColorEdit4('Main Color', c)) then
                            c = cflip(c);
                            settings.distance_font.color = imgui.ColorConvertFloat4ToU32(c);
                            need_font_update = true;
                        end
                        local sc = cflip({ imgui.ColorConvertU32ToFloat4(subcolor) });
                        if (imgui.ColorEdit4('Sub Range Color', sc)) then
                            sc = cflip(sc);
                            subcolor = imgui.ColorConvertFloat4ToU32(sc);
                            need_font_update = true;
                        end
                        local mc = cflip({ imgui.ColorConvertU32ToFloat4(maxcolor) });
                        if (imgui.ColorEdit4('Max Range Color', mc)) then
                            mc = cflip(mc);
                            maxcolor = imgui.ColorConvertFloat4ToU32(mc);
                            need_font_update = true;
                        end

                        if (need_font_update) then
                            party_member_data:each(function (pmd)
                                if(pmd.distance ~= nil)then
                                    pmd.distance:apply(settings.distance_font);
                                end
                            end);
                            need_font_update = not need_font_update;
                            config.uiSettings.font_changed[1] = true;
                        end

                    imgui.EndChild();
                imgui.EndGroup();
                imgui.BeginGroup();
                    imgui.TextColored({ 1.0, 0.65, 0.26, 1.0 }, 'Other Settings');
                    imgui.BeginChild('other_settings', { 0, 120, }, true); 

                        imgui.Checkbox('Show Exclusions', settings.show_excluded);
                        imgui.ShowHelp('Toggles if excluded icons are displayed or not.');
                        local pos = { settings.x[1], settings.y[1] } 
                        if (imgui.InputInt2('Position', pos)) then
                            settings.x[1] = pos[1];
                            settings.y[1] = pos[2];
                        end
                        imgui.ShowHelp('The location where the status icons and distance text is displayed.');
                        local srange = { subrange[1] } 
                        if (imgui.InputInt('Sub Range Distance', srange)) then
                            subrange[1] = srange[1];
                        end
                        imgui.ShowHelp('Range where the distance text will change color to the sub range.');
                        local mrange = { maxrange[1] } 
                        if (imgui.InputInt('Max Range Distance', mrange)) then
                            maxrange[1] = mrange[1];
                        end
                        imgui.ShowHelp('Range where the distance text will change color to the maximum range.');

                    imgui.EndChild();
                imgui.EndGroup();

                if (imgui.Button("Reload", { 130, 20 })) then
                    AshitaCore:GetChatManager():QueueCommand(-1, "/addon reload partybuffs");
                end
                imgui.SameLine();
                if(imgui.Button("Restore Defaults", { 130, 20 })) then
                    settings.reset();
                    AshitaCore:GetChatManager():QueueCommand(-1, "/addon reload partybuffs");
                end

                imgui.EndTabItem();
            end
            if (imgui.BeginTabItem('Exclusions', nil)) then
                imgui.BeginGroup();
                if (imgui.BeginTabBar('##pb_exclusionsTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then

                    if (imgui.BeginTabItem('Magic', nil)) then

                        imgui.TextColored({ 1.0, 0.65, 0.26, 1.0 }, 'Magic');
                        imgui.BeginGroup();
                        if (imgui.BeginTabBar('##pb_exclusionsTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
                    
                            if (imgui.BeginTabItem('White Magic', nil)) then
                                if (imgui.BeginTabBar('##pb_whmexclusions', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
                                    if (imgui.BeginTabItem('Buffs', nil)) then
                                        Magic.white_magic_buffs_ids:each(function(id) 
                                            imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                        end);
                                        imgui.EndTabItem()
                                    end
                                    if (imgui.BeginTabItem('Debuffs', nil)) then
                                        Magic.white_magic_debuffs_ids:each(function(id) 
                                            imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                        end);
                                        imgui.EndTabItem()
                                    end
                                    imgui.EndTabBar()
                                end
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('Black Magic', nil)) then
                                if (imgui.BeginTabBar('##pb_blmexclusions', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
                                    if (imgui.BeginTabItem('Buffs', nil)) then
                                        Magic.black_magic_buffs_ids:each(function(id) 
                                            imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                        end);
                                        imgui.EndTabItem()
                                    end
                                    if (imgui.BeginTabItem('Debuffs', nil)) then
                                        Magic.black_magic_debuffs_ids:each(function(id) 
                                            imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                        end);
                                        imgui.EndTabItem()
                                    end
                                    imgui.EndTabBar()
                                end
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('Songs', nil)) then
                                Magic.song_ids:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('Ninjutsu', nil)) then
                                Magic.ninjutsu_ids:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('Summoning', nil)) then
                                Magic.summoning_ids:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('Dice Rolls', nil)) then
                                Magic.dice_roll_ids:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            imgui.EndTabBar();
                        end
                        imgui.EndGroup();

                        imgui.EndTabItem();
                    end
                    if (imgui.BeginTabItem('Jobs', nil)) then

                        imgui.TextColored({ 1.0, 0.65, 0.26, 1.0 }, 'Jobs');
                        imgui.BeginGroup();
                        if (imgui.BeginTabBar('##pb_jobsexclusionsTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
                            
                            if (imgui.BeginTabItem('WAR', nil)) then
                                Jobs.war:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('MNK', nil)) then
                                Jobs.mnk:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('WHM', nil)) then
                                Jobs.whm:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('BLM', nil)) then
                                Jobs.blm:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('RDM', nil)) then
                                Jobs.rdm:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('THF', nil)) then
                                Jobs.thf:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('PLD', nil)) then
                                Jobs.pld:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('DRK', nil)) then
                                Jobs.drk:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('BST', nil)) then
                                Jobs.bst:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('BRD', nil)) then
                                Jobs.brd:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('RNG', nil)) then
                                Jobs.rng:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('SAM', nil)) then
                                Jobs.sam:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('NIN', nil)) then
                                Jobs.nin:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('DRG', nil)) then
                                Jobs.drg:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('SMN', nil)) then
                                Jobs.smn:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('BLU', nil)) then
                                Jobs.blu:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('COR', nil)) then
                                Jobs.cor:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('PUP', nil)) then
                                Jobs.pup:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('DNC', nil)) then
                                Jobs.dnc:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('SCH', nil)) then
                                Jobs.sch:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('GEO', nil)) then
                                Jobs.geo:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
                            if (imgui.BeginTabItem('RUN', nil)) then
                                Jobs.run:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
        
                            imgui.EndTabBar();
                        end
                        imgui.EndGroup();

                        imgui.EndTabItem();
                    end
                    if (imgui.BeginTabItem('Other', nil)) then

                        imgui.TextColored({ 1.0, 0.65, 0.26, 1.0 }, 'Others');
                        imgui.BeginGroup();
                        if (imgui.BeginTabBar('##pb_othersexclusionsTabs', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton)) then
                            
                            if (imgui.BeginTabItem('Others', nil)) then
                                Other_statuses:each(function(id) 
                                    imgui.Checkbox(settings.status_effects[id].name, settings.status_effects[id].excluded);
                                end);
                                imgui.EndTabItem();
                            end
        
                            imgui.EndTabBar();
                        end
                        imgui.EndGroup();

                        imgui.EndTabItem();
                    end

                    imgui.EndTabBar();
                end
                imgui.EndGroup();

                imgui.EndTabItem();
            end
            imgui.EndTabBar();
        end
        imgui.End();
    end
    imgui.PopStyleColor(1);
    imgui.PopStyleVar(1);
end

return config;