if string.lower(RequiredScript) == "lib/managers/hud/hudobjectives" then

	HUDObjectives._TEXT_MARGIN = 8
	HUDObjectives._MAX_WIDTH = 300
	HUDObjectives._FONT_SIZE = tweak_data.hud.active_objective_title_font_size
	HUDObjectives._BOUNCE = 12

	local init_original = HUDObjectives.init
	local activate_objective_original = HUDObjectives.activate_objective
	local update_amount_objective_original = HUDObjectives.update_amount_objective
	local remind_objective_original = HUDObjectives.remind_objective
	local complete_objective_original = HUDObjectives.complete_objective

	function HUDObjectives:init(hud)
		if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then

			if alive(self._panel) then
				hud.panel:remove(self._panel)
			end

			self._panel = hud.panel:panel({
				visible = false,
				name = "objectives_panel",
				h = 130,
				w = 400,
				x = 80,
				valign = "top"
			})

			self._bg_box = HUDBGBox_create(self._panel, {
				w = 400,
				h = 38,
			})

			self._objective_text = self._bg_box:text({
				name = "objective_text",
				visible = false,
				layer = 2,
				color = Color.white,
				text = "",
				font_size = HUDObjectives._FONT_SIZE,
				font = tweak_data.hud.medium_font_noshadow,
				align = "left",
				vertical = "center",
				w = self._bg_box:w(),
				x = HUDObjectives._TEXT_MARGIN,
				y = HUDObjectives._TEXT_MARGIN,
				wrap = false,
				word_wrap = false
			})

			self._amount_text = self._bg_box:text({
				name = "amount_text",
				visible = false,
				layer = 2,
				color = Color.white,
				text = "",
				font_size = HUDObjectives._FONT_SIZE,
				font = tweak_data.hud.medium_font_noshadow,
				align = "left",
				vertical = "center",
				w = self._bg_box:w(),
				h = HUDObjectives._FONT_SIZE,
				x = HUDObjectives._TEXT_MARGIN,
				y = HUDObjectives._TEXT_MARGIN
			})
		else
			return init_original(self, hud)
		end
	end

	function HUDObjectives:activate_objective(data)
		if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then
		
			self._active_objective_id = data.id
			self._panel:set_visible(true)
			self._objective_text:set_visible(true)
			self._amount_text:set_visible(false)

			local width, height, wrapped_text = self:_get_wrapped_text_dimensions(utf8.to_upper(data.text))

			self._objective_text:set_text(wrapped_text)
			self._objective_text:set_w(width)
			self._objective_text:set_h(height)
			self._bg_box:set_h(HUDObjectives._TEXT_MARGIN * 2 + height)

			if data.amount then
				self:update_amount_objective(data, true)
			else
				self._amount_text:set_text("")
				self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 2 + width)
			end
			if not self._active_move then
				self._bg_box:stop()
				self._bg_box:animate(callback(self, self, "_animate_update_objective"))
			end
		else
			return activate_objective_original(self, data)
		end
	end

	function HUDObjectives:update_amount_objective(data, hide_animation)
		
		if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then
			
			if data.id ~= self._active_objective_id then
				return
			end
			local amount = (data.current_amount or 0)
			self._amount_text:set_text(amount .. "/" .. data.amount)
			self._amount_text:set_left(self._objective_text:right() + HUDObjectives._TEXT_MARGIN)
			self._amount_text:set_bottom(self._objective_text:h() + HUDObjectives._TEXT_MARGIN)
			self._bg_box:set_w(HUDObjectives._TEXT_MARGIN * 3 + self._objective_text:w() + self:_get_text_dimensions(self._amount_text:text()).w)
			self._amount_text:set_visible(true)
			self._amount_text:stop()
			if not hide_animation and amount > 0 then
				self._amount_text:animate(callback(self, self, "_animate_new_amount"))
			else
				self._amount_text:set_color(Color(1, 1, 1, 1))
			end
		else
			return update_amount_objective_original(self, data, hide_animation)
		end
	end

	function HUDObjectives:remind_objective(id)
		
		if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then
		
			if id ~= self._active_objective_id then
				return
			end
			if not self._active_move then
				self._bg_box:stop()
				self._bg_box:animate(callback(self, self, "_animate_update_objective"))
			end
		else
			return remind_objective_original(self, id)
		end
	end

	function HUDObjectives:complete_objective(data)
		
		if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then
			
			if data.id ~= self._active_objective_id then
				return
			end

			self._active_objective_id = ""
			self._amount_text:set_visible(false)
			self._objective_text:set_visible(false)
			self._panel:set_visible(false)
			self._bg_box:set_w(0)

			self:apply_offset(self._offset_y)
		else
			return complete_objective_original(self, data)
		end
	end

	if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then

		function HUDObjectives:_animate_new_amount(object)
			local TOTAL_T = 2
			local t = TOTAL_T
			object:set_color(Color(1, 1, 1, 1))
			while t > 0 do
				local dt = coroutine.yield()
				t = t - dt
				object:set_color(Color(1, 1 , 1, 1 - (0.5 * math.sin(t * 360 * 2) + 0.5)))
			end
			object:set_color(Color(1, 1, 1, 1))
		end

		function HUDObjectives:_animate_update_objective(object)
			local TOTAL_T = 2
			local t = TOTAL_T
			object:set_y(self._offset_y or 0)
			while t > 0 do
				local dt = coroutine.yield()
				t = t - dt
				object:set_y((self._offset_y or 0) + math.round((1 + math.sin((TOTAL_T - t) * 450 * 2)) * (HUDObjectives._BOUNCE * (t / TOTAL_T))))
			end
			object:set_y(self._offset_y or 0)
		end

		function HUDObjectives:_get_text_dimensions(text_string)
			local string_width_measure_text_field = self._panel:child("string_dimensions") or self._panel:text({
				name = "string_dimensions",
				visible = false,
				font_size = HUDObjectives._FONT_SIZE,
				font = tweak_data.hud.medium_font_noshadow,
				align = "left",
				vertical = "center",
				wrap = false
			})
			string_width_measure_text_field:set_text(text_string)
			local x, y, w, h = string_width_measure_text_field:text_rect()
			return {x = x, y = y, w = w, h = h}
		end

		function HUDObjectives:_get_wrapped_text_dimensions(text_string)
			local layout_text_field = self._panel:child("layout") or self._panel:text({
				name = "layout",
				width = self._MAX_WIDTH,
				visible = false,
				font_size = HUDObjectives._FONT_SIZE,
				font = tweak_data.hud.medium_font_noshadow,
				align = "left",
				vertical = "center",
				wrap = true,
				word_wrap = true
			})
			layout_text_field:set_text(text_string)
			local line_breaks = table.collect(layout_text_field:line_breaks(), function(index)
				return index + 1
			end)
			local wrapped_lines = {}
			for line = 1, #line_breaks do
				local range_start = line_breaks[line]
				local range_end = line_breaks[line + 1]
				local string_range = utf8.sub(text_string, range_start, (range_end or 0) - 1)
				table.insert(wrapped_lines, string.trim(string_range))
			end
			local wrapped_text = ""
			local w, h = 0, layout_text_field:font_size() * math.max(#wrapped_lines, 1)
			for _, line in ipairs(wrapped_lines) do
				w = math.max(w, self:_get_text_dimensions(line).w)
				wrapped_text = string.format("%s%s\n", wrapped_text, line)
			end
			return math.ceil(w), math.ceil(h), wrapped_text
		end

		function HUDObjectives:apply_offset(offset)
			return
		end

		function HUDObjectives:_animate_move(panel, x, y, instant)
			self._active_move = true
			if not instant then
				local move_speed = 150
				local init_x = panel:x()
				local init_y = panel:y()
				local x_change = x > init_x and 1 or x < init_x and -1
				local y_change = y > init_y and 1 or y < init_y and -1
				local T = math.max(math.abs(x - init_x) / move_speed, math.abs(y - init_y) / move_speed)
				local t = 0

				while alive(panel) and t < T do
					if x_change then
						panel:set_x(init_x  + t * x_change * move_speed)
					end
					if y_change then
						panel:set_y(init_y  + t * y_change * move_speed)
					end
					t = t + coroutine.yield()
				end
			end

			if alive(panel) then
				panel:set_x(x)
				panel:set_y(y)
			end
			self._active_move = nil
		end
	end

elseif string.lower(RequiredScript) == "lib/managers/hud/hudheisttimer" then
	local init_original_time = HUDHeistTimer.init
	function HUDHeistTimer:init(hud, tweak_hud)
		
		if VHUDPlus:getSetting({"CustomHUD", "ENABLED_ENHANCED_OBJECTIVE"}, false) then
			
			self._hud_panel = hud.panel
			self._enabled = not (tweak_hud and tweak_hud.no_timer)
			if self._hud_panel:child("heist_timer_panel") then
				self._hud_panel:remove(self._hud_panel:child("heist_timer_panel"))
			end

			self._heist_timer_panel = self._hud_panel:panel({
				visible = self._enabled,
				name = "heist_timer_panel",
				h = 40,
				w = 80,
				valign = "top",
				layer = 0
			})
			self._timer_text = self._heist_timer_panel:text({
				name = "timer_text",
				text = "00:00:00",
				font_size = tweak_data.hud.medium_deafult_font_size,
				font = tweak_data.hud.medium_font_noshadow,
				color = Color.white,
				align = "center",
				vertical = "center",
				layer = 1,
				wrap = false,
				word_wrap = false
			})

			self._last_time = 0
		else
			return init_original_time(self, hud, tweak_hud)
		end
	end

elseif string.lower(RequiredScript) == "core/lib/managers/subtitle/coresubtitlepresenter" then
	core:module("CoreSubtitlePresenter")
	function OverlayPresenter:show_text(text, duration)
		self.__font_name = "fonts/font_medium_mf"
		self._text_scale = _G.VHUDPlus:getSetting({"MISCHUD", "SCALE"}, 1)
		local text_shadow = _G.VHUDPlus:getSetting({"MISCHUD", "SUB"}, true)
		local label = self.__subtitle_panel:child("label") or self.__subtitle_panel:text({
			name = "label",
			font = self.__font_name,
			font_size = self.__font_size * self._text_scale,
			color = Color.white,
			align = "center",
			vertical = "bottom",
			layer = 1,
			wrap = true,
			word_wrap = true
		})
		local shadow = self.__subtitle_panel:child("shadow") or self.__subtitle_panel:text({
			name = "shadow",
			x = 1,
			y = 1,
			font = self.__font_name,
			font_size = self.__font_size * self._text_scale,
			color = Color.black:with_alpha(1),
			align = "center",
			vertical = "bottom",
			layer = 0,
			wrap = true,
			word_wrap = true
		})
		label:set_text(text)
		shadow:set_text(text)	
		label:set_font_size(self.__font_size * self._text_scale)
		shadow:set_font_size(self.__font_size * self._text_scale)
		shadow:set_visible(text_shadow)
	end
	
	local _on_resolution_changed_original = OverlayPresenter._on_resolution_changed
	function OverlayPresenter:_on_resolution_changed(...)
		_on_resolution_changed_original(self, ...)
		self:apply_bottom_offset()
	end

	function OverlayPresenter:set_bottom(offset)
		if self._bottom_off ~= offset then
			self._bottom_off = offset
			self:apply_bottom_offset()
		end
	end

	function OverlayPresenter:apply_bottom_offset()
		if self.__subtitle_panel then
			self.__subtitle_panel:set_height(_G.VHUDPlus:getSetting({"MISCHUD", "SUB_HEIGHT"}, 600))
			local label = self.__subtitle_panel:child("label")
			if label then
				label:set_h(self.__subtitle_panel:h())
				label:set_w(self.__subtitle_panel:w())
			end
			local shadow = self.__subtitle_panel:child("shadow")
			if shadow then
				shadow:set_h(self.__subtitle_panel:h())
				shadow:set_w(self.__subtitle_panel:w())
			end
		end
	end
end
