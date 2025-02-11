if string.lower(RequiredScript) == "lib/managers/hudmanagerpd2" then
	local set_slot_ready_orig = HUDManager.set_slot_ready
	local set_teammate_ammo_amount_orig = HUDManager.set_teammate_ammo_amount

	function HUDManager:set_teammate_ammo_amount(id, selection_index, max_clip, current_clip, current_left, max, ...)
		if VHUDPlus:getSetting({"CustomHUD", "USE_REAL_AMMO"}, true) and VHUDPlus:getSetting({"CustomHUD", "HUDTYPE"}, 2) == 3 then
			local total_left = current_left - current_clip
			if total_left >= 0 then
				current_left = total_left
				max = max - current_clip
			end
		end
		return set_teammate_ammo_amount_orig(self, id, selection_index, max_clip, current_clip, current_left, max, ...)
	end

	local FORCE_READY_CLICKS = 3
	local FORCE_READY_TIME = 2
	local FORCE_READY_ACTIVE_T = 90

	local force_ready_start_t = 0
	local force_ready_clicked = 0

	function HUDManager:set_slot_ready(peer, peer_id, ...)
		set_slot_ready_orig(self, peer, peer_id, ...)

		if Network:is_server() and not Global.game_settings.single_player then
			local session = managers.network and managers.network:session()
			local local_peer = session and session:local_peer()
			local time_elapsed = managers.game_play_central and managers.game_play_central:get_heist_timer() or 0
			if local_peer and local_peer:id() == peer_id then
				local t = Application:time()
				if (force_ready_start_t + FORCE_READY_TIME) > t then
					force_ready_clicked = force_ready_clicked + 1
					if force_ready_clicked >= FORCE_READY_CLICKS then
						local enough_wait_time = (time_elapsed > FORCE_READY_ACTIVE_T)
						local friends_list = not enough_wait_time and Steam:logged_on() and Steam:friends() or {}
						local abort = false
						for _, peer in ipairs(session:peers()) do
							local is_friend = false
							for _, friend in ipairs(friends_list) do
								if friend:id() == peer:user_id() then
									is_friend = true
									break
								end
							end
							if not (enough_wait_time or is_friend) or not (peer:synced() or peer:id() == local_peer:id()) then
								abort = true
								break
							end
						end
						if game_state_machine and not abort then
							local menu_options = {
								[1] = {
									text = managers.localization:text("dialog_yes"),
									callback = function(self, item)
										managers.chat:send_message(ChatManager.GAME, local_peer, managers.localization:text("wolfhud_dialog_force_start_msg"))
										game_state_machine:current_state():start_game_intro()
									end,
								},
								[2] = {
									text = managers.localization:text("dialog_no"),
									is_cancel_button = true,
								}
							}
							QuickMenu:new( managers.localization:text("wolfhud_dialog_force_start_title"), managers.localization:text("wolfhud_dialog_force_start_desc"), menu_options, true )
						end
					end
				else
					force_ready_clicked = 1
					force_ready_start_t = t
				end
			end
		end
	end
	
    local ability_radial = HUDManager.set_teammate_ability_radial
    function HUDManager:set_teammate_ability_radial(i, data)
	    local hud = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
	    if not hud.panel:child("chico_injector_left") then
		    local chico_injector_left = hud.panel:bitmap({
			    name = "chico_injector_left",
			    visible = false,
			    texture = "assets/guis/textures/custom_effect",
			    layer = 0,
			    color = Color(1, 0.6, 0),
			    blend_mode = "add",
			    w = hud.panel:w(),
			    h = hud.panel:h(),
			    x = 0,
			    y = 0 
		    })
	    end
	    local chico_injector_left = hud.panel:child("chico_injector_left")
	    if i == 4 and data.current < data.total and data.current > 0 and chico_injector_left then
		    chico_injector_left:set_visible(VHUDPlus:getSetting({"MISCHUD", "KINGPIN_EFFECT"}, true))
		    local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		    chico_injector_left:animate(hudinfo.flash_icon, 4000000000)
	    elseif hud.panel:child("chico_injector_left") then
		    chico_injector_left:stop()
		    chico_injector_left:set_visible(false)
	    end
	    if chico_injector_left and data.current == 0 then
		    chico_injector_left:set_visible(false)
	    end
	    return ability_radial(self, i, data)
    end

local custom_radial = HUDManager.set_teammate_custom_radial
    function HUDManager:set_teammate_custom_radial(i, data)
	    local hud = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
	    if not hud.panel:child("swan_song_left") then
		    local swan_song_left = hud.panel:bitmap({
			    name = "swan_song_left",
			    visible = false,
			    texture = "assets/guis/textures/custom_effect",
			    layer = 0,
			    color = Color(0, 0.7, 1),
			    blend_mode = "add",
			    w = hud.panel:w(),
			    h = hud.panel:h(),
			    x = 0,
			    y = 0 
		    })
	    end
	    local swan_song_left = hud.panel:child("swan_song_left")
	    if i == 4 and data.current < data.total and data.current > 0 and swan_song_left then
		    swan_song_left:set_visible(VHUDPlus:getSetting({"MISCHUD", "SWAN_SONG_EFFECT"}, true))
		    local hudinfo = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		    swan_song_left:animate(hudinfo.flash_icon, 4000000000)
	    elseif hud.panel:child("swan_song_left") then
		    swan_song_left:stop()
		    swan_song_left:set_visible(false)
	    end
	    if swan_song_left and data.current == 0 then
		    swan_song_left:set_visible(false)
	    end
	    return custom_radial(self, i, data)
    end

	Hooks:PreHook(HUDManager, "_setup_player_info_hud_pd2", "wolfhud_scaling", function(self)
		if HSAS or NepgearsyHUDReborn then return end
		managers.gui_data:layout_scaled_fullscreen_workspace(managers.hud._saferect)
	end)

	function HUDManager:recreate_player_info_hud_pd2()
		if HSAS or NepgearsyHUDReborn then return end
		if not self:alive(PlayerBase.PLAYER_INFO_HUD_PD2) then return end
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
		self:_create_teammates_panel(hud)
		self:_create_present_panel(hud)
		self:_create_interaction(hud)
		self:_create_progress_timer(hud)
		self:_create_objectives(hud)
		self:_create_hint(hud)
		self:_create_heist_timer(hud)
		self:_create_temp_hud(hud)
		self:_create_suspicion(hud)
		self:_create_hit_confirm(hud)
		self:_create_hit_direction(hud)
		self:_create_downed_hud()
		self:_create_custody_hud()
		self:_create_hud_chat()
		self:_create_assault_corner()
		self:_create_waiting_legend(hud)
		self:_create_accessibility(hud)
	end

	core:module("CoreGuiDataManager")
	function GuiDataManager:layout_scaled_fullscreen_workspace(ws)
		if HSAS or NepgearsyHUDReborn then return end
		local base_res = {x = 1280, y = 720}
		local res = RenderSettings.resolution
		local sc = (2 - _G.VHUDPlus:getSetting({"CustomHUD", "HUD_SCALE"}, 1))
		local aspect_width = base_res.x / self:_aspect_ratio()
		local h = math.round(sc * math.max(base_res.y, aspect_width))
		local w = math.round(sc * math.max(base_res.x, aspect_width / h))

		local safe_w = math.round(0.95 * res.x)
		local safe_h = math.round(0.95 * res.y)   
		local sh = math.min(safe_h, safe_w / (w / h))
		local sw = math.min(safe_w, safe_h * (w / h))
		local x = res.x / 2 - sh * (w / h) / 2
		local y = res.y / 2 - sw / (w / h) / 2
		ws:set_screen(w, h, x, y, math.min(sw, sh * (w / h)))
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/timespeedeffecttweakdata" then
	local init_original = TimeSpeedEffectTweakData.init
	local FORCE_ENABLE = {
		mission_effects = true,
	}
	function TimeSpeedEffectTweakData:init(...)
		init_original(self, ...)
		if VHUDPlus:getSetting({"SkipIt", "NO_SLOWMOTION"}, true) then
			local function disable_effect(table)
				for name, data in pairs(table) do
					if not FORCE_ENABLE[name] then
						if data.speed and data.sustain then
							data.speed = 1
							data.fade_in_delay = 0
							data.fade_in = 0
							data.sustain = 0
							data.fade_out = 0
						elseif type(data) == "table" then
							disable_effect(data)
						end
					end
				end
			end

			disable_effect(self)
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/experiencemanager" then
	local cash_string_original = ExperienceManager.cash_string

	function ExperienceManager:cash_string(...)
		local val = cash_string_original(self, ...)
		if self._cash_sign ~= "$" and val:find(self._cash_sign) then
			val = val:gsub(self._cash_sign, "") .. self._cash_sign
		end
		return val
	end
elseif string.lower(RequiredScript) == "lib/managers/moneymanager" then
	function MoneyManager:total_string()
		local total = math.round(self:total())
		return managers.experience:cash_string(total)
	end
	function MoneyManager:total_collected_string()
		local total = math.round(self:total_collected())
		return managers.experience:cash_string(total)
	end
elseif string.lower(RequiredScript) == "lib/units/weapons/raycastweaponbase" then

    local init_original = RaycastWeaponBase.init
    local setup_original = RaycastWeaponBase.setup
	
	function RaycastWeaponBase:init(...)
		if not VHUDPlus:getSetting({"MISCHUD", "SHOOT_THROUGH_BOTS"}, true) then
			return init_original(self, ...)
		end
		init_original(self, ...)
	    self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
    end

    function RaycastWeaponBase:setup(...)
		if not VHUDPlus:getSetting({"MISCHUD", "SHOOT_THROUGH_BOTS"}, true) then
			return setup_original(self, ...)
		end
		setup_original(self, ...)
	    self._bullet_slotmask = self._bullet_slotmask - World:make_slot_mask(16)
    end
elseif string.lower(RequiredScript) == "lib/units/contourext" then
	local add_original = ContourExt.add
    if VHUDPlus:getSetting({"MISCHUD", "JOKER_CONTOUR_NEW"}, true) and not FadingContour then
	    function ContourExt:add(type, ...)
		    local result = add_original(self, type, ...)
		    local default_friendly_color = ContourExt._types.friendly.color
		    ContourExt._types.friendly.color = nil
		
		    if result and type == "friendly" then
			    self:change_color("friendly", default_friendly_color)
		    end
		
		    local function joker_event(event, key, data)
			    if data.owner then
				    managers.gameinfo:add_scheduled_callback(key .. "_joker_contour", 0.01, function()
					    if alive(data.unit) and data.unit:contour() then
						    data.unit:contour():change_color("friendly", tweak_data.chat_colors[data.owner] or default_friendly_color)
					    end
				    end)
			    end
		    end
		    managers.gameinfo:register_listener("joker_contour_listener", "minion", "set_owner", joker_event)
		    return result
	    end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/weapontweakdata" then
    local init_original = WeaponTweakData.init

    function WeaponTweakData:init(tweak_data)
        init_original(self, tweak_data)
        self.basset_crew.rays = 6
        self.x_basset_crew.rays = 6
    end	
elseif string.lower(RequiredScript) == "lib/managers/objectinteractionmanager" then
	local init_original = ObjectInteractionManager.init

	function ObjectInteractionManager:init(...)
		init_original(self, ...)
		if managers.gameinfo and VHUDPlus:getSetting({"HUDSuspicion", "REMOVE_ANSWERED_PAGER_CONTOUR"}, true) then
			managers.gameinfo:register_listener("pager_contour_remover", "pager", "set_answered", callback(nil, _G, "pager_answered_clbk"))
		end
	end

	function pager_answered_clbk(event, key, data)
		managers.enemy:add_delayed_clbk("contour_remove_" .. key, callback(nil, _G, "remove_answered_pager_contour_clbk", data.unit), Application:time() + 0.01)
	end

	function remove_answered_pager_contour_clbk(unit)
		if alive(unit) then
			unit:contour():remove(tweak_data.interaction.corpse_alarm_pager.contour_preset)
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudassaultcorner" then
	local HUDAssaultCorner_init = HUDAssaultCorner.init
	function HUDAssaultCorner:init(...)
		HUDAssaultCorner_init(self, ...)
		local hostages_panel = self._hud_panel:child("hostages_panel")
		if alive(hostages_panel) and VHUDPlus:getSetting({"HUDList", "ENABLED"}, true) and not VHUDPlus:getSetting({"HUDList", "ORIGNIAL_HOSTAGE_BOX"}, false) then
			hostages_panel:set_alpha(0)
		end
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/levelstweakdata" then
    local _get_music_event_orig = LevelsTweakData.get_music_event
    function LevelsTweakData:get_music_event(stage)
        local result = _get_music_event_orig(self, stage)
        if result and VHUDPlus:getSetting({"MISCHUD", "SHUFFLE_MUSIC"}, true) and stage == "control" then
            if self.can_change_music then
                managers.music:check_music_switch()
            else
                self.can_change_music = true
            end
        end
        return result
    end	
elseif string.lower(RequiredScript) == "lib/managers/hud/hudteammate" then
	local set_ammo_amount_by_type_orig = HUDTeammate.set_ammo_amount_by_type
	function HUDTeammate:set_ammo_amount_by_type(type, max_clip, current_clip, current_left, max, weapon_panel, ...)
		if VHUDPlus:getSetting({"CustomHUD", "USE_REAL_AMMO"}, true) then
			if current_left - current_clip >= 0 then
				current_left = current_left - current_clip
			end
		end
		
		return set_ammo_amount_by_type_orig(self, type, max_clip, current_clip, current_left, max, weapon_panel, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/hud/hudpresenter" then
	local _present_done_orig = HUDPresenter._present_done
	function HUDPresenter:_present_done()
		_present_done_orig(self)
		local present_panel = managers.hud._hud_presenter._hud_panel:child("present_panel")
		present_panel:set_visible(false)
		managers.hud._hud_presenter:_present_done()
	end
elseif string.lower(RequiredScript) == "core/lib/managers/menu/reference_input/coremenuinput" then
	core:module("CoreMenuInput")
	core:import("CoreDebug")
	core:import("CoreMenuItem")
	core:import("CoreMenuItemSlider")
	core:import("CoreMenuItemToggle")	

	function MenuInput:update(t, dt)
		self:_check_releases()
		self:any_keyboard_used()
	
		local axis_timer = self:axis_timer()
	
		if axis_timer.y > 0 then
			self:set_axis_y_timer(axis_timer.y - dt)
		end
	
		if axis_timer.x > 0 then
			self:set_axis_x_timer(axis_timer.x - dt)
		end
	
		if self:_input_hijacked() then
			local item = self._logic:selected_item()
	
			if item and item.INPUT_ON_HIJACK then
				self._item_input_action_map[item.TYPE](item, self._controller)
			end
	
			return false
		end
	
		if self._accept_input and self._controller then
			if axis_timer.y <= 0 then
				if self:menu_up_input_bool() then
					self:prev_item()
					self:set_axis_y_timer(0.12)
	
					if self:menu_up_pressed() then
						self:set_axis_y_timer(0.3)
					end
				elseif self:menu_down_input_bool() then
					self:next_item()
					self:set_axis_y_timer(0.12)
	
					if self:menu_down_pressed() then
						self:set_axis_y_timer(0.3)
					end
				end
			end
	
			if axis_timer.x <= 0 then
				local item = self._logic:selected_item()
	
				if item then
					self._item_input_action_map[item.TYPE](item, self._controller)
				end
			end
	
			if self._controller:get_input_pressed("menu_toggle_legends") then
				print("update something")
				self._logic:update_node()
			end

			if self._controller:get_input_pressed("menu_update") then
				managers.menu:open_node("crimenet_filters", {})
				-- managers.menu_component:disable_crimenet()
				self._logic:update_node()
				-- managers.network.matchmake:load_user_filters()
				managers.network.matchmake:search_lobby(managers.network.matchmake:search_friends_only())
			end
		end
	
		return true
	end
end