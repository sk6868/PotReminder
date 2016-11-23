local addonName, ns = ...

local L = ns.L
local f = CreateFrame("Frame", "PotReminderFrame")

local Ambiguate = Ambiguate
local UnitDebuff = UnitDebuff
local UnitExists = UnitExists
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitBuff = UnitBuff
local UnitName = UnitName
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetSpellInfo = GetSpellInfo

local defaults = {
	enabled = true,
	lfr = true,
	normal = true,
	to_chat = true,
	play_sound = false,
	pot_check = true,
	potcheck_delay = 5,
	pot_rw = false,
	pot_colors = false,
}

local _usage = [[
PotReminder Usage
/pr debug <toggle debug>
/pr on    <enable pr>
/pr off   <disable pr>
/pr test  <test PotReminder>
/pr sound <toggle sound>
]]
local _debug = false
local prepull_delay = 750 -- in milliseconds

ns.difficulty = 0

local function NOOP() end

function ns:Print(...)
    print(GREEN_FONT_COLOR_CODE .. "PR:" .. FONT_COLOR_CODE_CLOSE, ...)
end

function ns:_debugPrintf(str, ...)
	if _debug then
		self:Print(GRAY_FONT_COLOR_CODE .. str:format(...) .. FONT_COLOR_CODE_CLOSE)
	end
end

function ns:LFR()
	return self.difficulty == 7 or self.difficulty == 17
end

function ns:Normal()
	return self.difficulty == 1 or self.difficulty == 3 or self.difficulty == 4 or self.difficulty == 14
end

function ns:Heroic()
	return self.difficulty == 2 or self.difficulty == 5 or self.difficulty == 6 or self.difficulty == 15
end

function ns:Mythic()
	return self.difficulty == 16
end

-- Blizzard Interface Options Panel stuff START
function ns:_CreateOptionsPanel()
	local function newCheckbox(parent, name, label, description, onClick)
		local check = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
		check:SetScript("OnClick", function(self)
			PlaySound(self:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
			onClick(self, self:GetChecked() and true or false)
		end)
		check.label = _G[name .. "Text"]
		check.label:SetText(label)
		check.tooltipText = label
		check.tooltipRequirement = description
		return check
	end
	local panel = CreateFrame( "Frame", "PotReminderOptionsPanel", UIParent )
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L["General Options"])
	local version_str = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version_str:SetPoint("TOPLEFT", 200, -21)
	version_str:SetVertexColor(0.0, 1.0, 0.0, 1.0)
	version_str:SetText(addonName..L[" Version: "]..self.version)

	panel.checkbox1 = newCheckbox(panel, "PotReminderOptionCheck1",
		L["Enable"],
		L["Toggle addon enable"],
		function(self, value) PotReminderDB.enabled = value end)
	panel.checkbox1:SetChecked(PotReminderDB.enabled)
	panel.checkbox1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)
	
	panel.checkbox2 = newCheckbox(panel, "PotReminderOptionCheck2",
		L["LFR"],
		L["Enable in LFR"],
		function(self, value) PotReminderDB.lfr = value end)
	panel.checkbox2:SetChecked(PotReminderDB.lfr)
	panel.checkbox2:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -46)
	
	panel.checkbox3 = newCheckbox(panel, "PotReminderOptionCheck3",
		L["Normal"],
		L["Enable in Normal mode"],
		function(self, value) PotReminderDB.normal = value end)
	panel.checkbox3:SetChecked(PotReminderDB.normal)
	panel.checkbox3:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -76)
	
	panel.checkbox4 = newCheckbox(panel, "PotReminderOptionCheck4",
		L["Enable Sound"],
		L["Enable Sound"],
		function(self, value) PotReminderDB.play_sound = value end)
	panel.checkbox4:SetChecked(PotReminderDB.play_sound)
	panel.checkbox4:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -106)
	
	panel.checkbox5 = newCheckbox(panel, "PotReminderOptionCheck5",
		L["ChatAlert"],
		L["Alert to chat"],
		function(self, value) PotReminderDB.to_chat = value end)
	panel.checkbox5:SetChecked(PotReminderDB.to_chat)
	panel.checkbox5:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -136)

	panel.checkbox5a = newCheckbox(panel, "PotReminderOptionCheck5a",
		L["ClassColors"],
		L["Show class colors"],
		function(self, value) PotReminderDB.pot_colors = value end)
	panel.checkbox5a:SetChecked(PotReminderDB.pot_colors)
	panel.checkbox5a:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -166)
	
	panel.checkbox6 = newCheckbox(panel, "PotReminderOptionCheck6",
		L["PotCheck"],
		L["Check for lust pot"],
		function(self, value) PotReminderDB.pot_check = value end)
	panel.checkbox6:SetChecked(PotReminderDB.pot_check)
	panel.checkbox6:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -208)
	
	-- create slider for potions check time
	panel.slider1 = self:CreateSlider(panel, 'potionCheckSlider', 
		L["Seconds after lust to check"], 0, 40, 200, 20, 2, PotReminderDB.potcheck_delay)
	panel.slider1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 150, -208)
	
	panel.checkbox5b = newCheckbox(panel, "PotReminderOptionCheck5b",
		L["SendtoChat"],
		L["Send to RW or Raid chat"],
		function(self, value) PotReminderDB.pot_rw = value end)
	panel.checkbox5b:SetChecked(PotReminderDB.pot_rw)
	panel.checkbox5b:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -240)
	
	-- Register in the Interface Addon Options GUI
	-- Set the name for the Category for the Options Panel
	panel.name = L["Pot Reminder"]

	-- Add the panel to the Interface Options
	InterfaceOptions_AddCategory(panel)
	
	return panel
end

function ns:_OpenOptionsPanel()
	if InterfaceOptionsFrame:IsVisible() then
		InterfaceOptionsFrame_Show()
	else
		InterfaceOptionsFrame_OpenToCategory(self.panel)
		InterfaceOptionsFrame_OpenToCategory(self.panel)
	end
end
-- Blizzard Interface Options Panel stuff END

function ns:CheckIfBossEngaged()
	if IsEncounterInProgress() then
		if UnitExists('boss1') or UnitExists('boss2') or UnitExists('boss3') then
			return true
		end
	end
	return false
end

local potions = {}
local elixirs = {}

local LustSpells = {
	[2825] = true, -- Bloodlust
--    [32182] = true, -- Heroism
	[80353] = true, -- Time Warp
	[90355] = true, -- Ancient Hysteria
	[178207] = true, -- Drums of Fury
	[160452] = true, -- Netherwinds, Nether Ray (hunter pet)
}

local SatedDebuffs = {
	80354, -- Temporal Displacement (applied by Time Warp)
	95809, -- Insanity (applied by Ancient Hysteria)
	57724, -- Sated (applied by Bloodlust)
	57723, -- Exhaustion (applied by Heroism and Drums of Fury)
	160455, -- Fatigued (Netherwinds sated version)
}

local escapes = {
    ["|c%x%x%x%x%x%x%x%x"] = "", -- color start
    ["|r"] = "", -- color end
}
local function unescape(str)
    for k, v in pairs(escapes) do
        str = gsub(str, k, v)
    end
    return str
end

function ns:SendToChat(chatMessage)
	self:_debugPrintf("SendToChat")
	if IsInRaid() and IsInInstance() then
		if PotReminderDB.pot_rw and (not self:LFR()) then -- disable rw or raid chat in LFR
			if UnitIsGroupAssistant("player") or UnitIsGroupLeader("player") then
				SendChatMessage(unescape(chatMessage), "RAID_WARNING")
			else
				SendChatMessage(unescape(chatMessage), IsPartyLFG() and "INSTANCE_CHAT" or "RAID")
			end
		else
			self:Print(chatMessage)
		end
	else
		-- totally disable in non-raid environments
		--[[
		if PotReminderDB.pot_rw then
			SendChatMessage(chatMessage, "SAY", nil, nil)
		else
			self:Print(ICON_LIST[1].."0|t"..chatMessage)
		end
		]]--
	end
end

local function CalcDebuff(uid, debuff) -- to fill some information gaps of UnitDebuff()
	local name, icon, count, dur, expirationTime, caster, sdur, timeActive, start, dname
	dname = GetSpellInfo(debuff)
	if not dname then dname = debuff end

	name, _, icon, count, _, dur, expirationTime, caster = UnitDebuff(uid, dname)
	if (name == dname) then
		if dur and dur > 0 then
			sdur = dur
			start = expirationTime - dur
			timeActive = GetTime() - start
		else
			sdur = 0
			start = 0
		end
	end
	--return name, count, icon, start, sdur, caster, timeActive
	return timeActive
end

-- Check if an item is on cooldown
function ns:IsPotionOnCooldown(itemID)
	local name, link, _, _, _, itemType, itemSubType, _, _, icon = GetItemInfo(itemID)
	local found = false
	if name then
		--self:_debugPrintf("%s <%s> itemType=[%s], itemSubType=[%s]", link, itemID, itemType, itemSubType)
		-- check for shared cooldowns for potions/elixirs/flasks
		-- (exclude Crystal of Insanity, Oralius, and Draenor Healing Tonic)
		-- Healthstones share a cooldown with Tonics, but they are classified under "Other" in itemSubType
		if itemType == "Consumable" and (itemID ~= 86569) and (itemID ~= 118922) and (itemID ~= 109223) then
			if itemSubType == "Potion" then
				found = true
				potions[itemID] = true
			--elseif (itemSubType == "Elixir") or (itemSubType == "Flask") then
			--	found = true
			--	elixirs[itemID] = true
			end
		end
	end
	if found then
		self:_debugPrintf("******* %s", link)
		-- enable	1 if the item is ready or on cooldown
		-- 			0 if the item is used, but the cooldown didn't start yet (e.g. potion in combat).
		local start, duration, enable = GetItemCooldown(itemID)
		if enable == 1 then
			if start > 0 then
				self:_debugPrintf("%s [%s] on cooldown", link, itemID)
				return true
			end
		else
			return true
		end
	end
end

function ns:UpdatePotionCooldowns()
	self:_debugPrintf("UpdatePotionCooldowns")
	for bag = 0, NUM_BAG_SLOTS do
		for i = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, i)
			if itemID and self:IsPotionOnCooldown(itemID) then
				return true
			end
		end
	end
	return false
end

function ns:CheckForSated()
	self:_debugPrintf("CheckForSated")
	for i=1, #(SatedDebuffs) do
		--local name,_,_,_,dur,_,time_active = CalcDebuff('player', SatedDebuffs[i])
		local time_active = CalcDebuff('player', SatedDebuffs[i])
		if time_active and (time_active > 0.5) then
			self:_debugPrintf("CheckForSated return true (%.2f)", time_active)
			return true
		end
	end
end

function ns:CheckforValidLust(sourceName, spellID)
	--self:_debugPrintf("CheckforValidLust(%s, %d) type(spellID)=[%s]", sourceName, spellID, type(spellID))
	if (GetNumGroupMembers() > 0) and LustSpells[spellID] then
		sourceName = Ambiguate(sourceName, "none")
		-- UnitInParty/UnitInRaid/UnitIsUnit return nil if given Name-Realm of someone on the same realm
		--if UnitInRaid(sourceName) or UnitInParty(sourceName) then
		if UnitPlayerOrPetInRaid(sourceName) or UnitPlayerOrPetInParty(sourceName) then
		--if UnitInRaid(sourceName) or UnitInParty(sourceName) then
			self:_debugPrintf("CheckforValidLust(%s, %d)", sourceName, spellID)
			return (not self:CheckForSated())
		end
	end
	return false
end

function ns:ListenForLust(eventFrame, force)
	self:_debugPrintf("ListenForLust force=%s", tostring(force))
	if eventFrame:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED') then return end
	local isInstance, instanceType = IsInInstance()
	if PotReminderDB.enabled and isInstance and (instanceType == 'party' or instanceType == 'raid') then
		self.difficulty = select(3, GetInstanceInfo())
		local activate = true
		if self:LFR() and (not PotReminderDB.lfr) then
			activate = false
		elseif self:Normal() and (not PotReminderDB.normal) then
			activate = false
		end
		self:_debugPrintf("activate=[%s] CheckIfBossEngaged=[%s]", tostring(activate), tostring(self:CheckIfBossEngaged()))
		if activate and (force or self:CheckIfBossEngaged()) then
			eventFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
		end
	end
end

function ns:RemindMeToPot(sourceName, spellID)
	if self:CheckforValidLust(sourceName, spellID) then
		local msg, info = nil, nil
		self:_debugPrintf("RemindMeToPot(%s, %d)", sourceName, spellID)
		if self:UpdatePotionCooldowns() then
			if PotReminderDB.pot_colors then
				msg = L["MSG1"]:format("|c"..RAID_CLASS_COLORS[select(2, UnitClass(Ambiguate(sourceName,'none')))].colorStr..sourceName..FONT_COLOR_CODE_CLOSE)
			else
				msg = L["MSG1"]:format(sourceName)
			end
			info = ChatTypeInfo["SYSTEM"]
		else
			if PotReminderDB.pot_colors then
				msg = L["MSG2"]:format("|c"..RAID_CLASS_COLORS[select(2, UnitClass(Ambiguate(sourceName,'none')))].colorStr..sourceName..FONT_COLOR_CODE_CLOSE)
			else
				msg = L["MSG2"]:format(sourceName)
			end
			info = ChatTypeInfo["SYSTEM"]
		end
		self:_debugPrintf(msg)
		--UIErrorsFrame:AddMessage(msg, 1.0, 0.0, 0.0, info.id, UIERRORS_HOLD_TIME or 5)
		self:PlayAlert()
		if CombatText_AddMessage then
			CombatText_AddMessage(msg, COMBAT_TEXT_SCROLL_FUNCTION, 0.0, 1.0, 0.0, "crit", nil)
		end
		if PotReminderDB.to_chat then
			self:Print( msg )
		end
		if PotReminderDB.pot_check then
			self._potionchecktimer:Start(PotReminderDB.potcheck_delay * 1000, 'LUST', ns.CheckForPotionBuff)
		end
	end
end

local wod_potions = {
	156579, -- Draenic Strength Potion
	156578, -- Draenic Intellect Potion
	156577, -- Draenic Agility Potion
}

local leg_potions = {
	188028, -- Potion of the Old War
	188027, -- Potion of Deadly Grace
	229206, -- Potion of Prolonged Power
}

local no_prepull_potion = {}
local no_lust_potion = {}

local function History()
	if no_prepull_potion and (#no_prepull_potion > 0) then
		print(L["MSG0"]:format(prepull_delay/1000, table.concat(no_prepull_potion, ", ")))
	else
		print(L["MSG0"]:format(prepull_delay/1000, L["NONE"]))
	end
	if no_lust_potion and (#no_lust_potion > 0) then
		print(L["MSG0"]:format(PotReminderDB.potcheck_delay, table.concat(no_lust_potion, ", ")))
	else
		print(L["MSG0"]:format(PotReminderDB.potcheck_delay, L["NONE"]))
	end
end

-- no use checking IsEncounterInProgress here since it is unreliable @ ENCOUNTER_START
-- http://www.wowinterface.com/forums/showthread.php?t=48377
function ns.CheckForPotionBuff(timer)
	ns:_debugPrintf("CheckForPotionBuff[%s] IsInRaid[%s]", timer.flag, tostring(IsInRaid()))
	if (not IsInRaid()) then return end
	local no_potion = nil
	if timer.flag == 'PREPULL' then
		no_potion = no_prepull_potion
	elseif timer.flag == 'LUST' then
		no_potion = no_lust_potion
	end
	assert(no_potion ~= nil, "Critical Logic Error")
	wipe(no_potion)
	for rID = 1, GetNumGroupMembers() do
		local u = "raid"..rID
		local has = false
		if (UnitGroupRolesAssigned(u) == "DAMAGER") then
			--for _, wod_potion in ipairs(wod_potions) do
			for _, leg_potion in ipairs(leg_potions) do
				--if UnitBuff(u, GetSpellInfo(wod_potion)) then
				if UnitBuff(u, GetSpellInfo(leg_potion)) then
					has = true
					break
				end
			end
			if not has then
				if PotReminderDB.pot_colors then
					tinsert(no_potion, "|c"..RAID_CLASS_COLORS[select(2, UnitClass(u))].colorStr..UnitName(u)..FONT_COLOR_CODE_CLOSE)
				else
					tinsert(no_potion, (UnitName(u)))
				end
			end
		end
	end
	if (#no_potion > 0) then
		ns:SendToChat(L["MSG0"]:format(timer.durationMillis/1000, table.concat(no_potion, ", ")))
	else
		ns:SendToChat(L["MSG0"]:format(timer.durationMillis/1000, L["NONE"]))
	end
end

local function FrameOnEvent(frame, event, ...)
	local msg = ...
	if (event == 'ADDON_LOADED') and (msg == addonName) then
		frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- need these two in case we reload incombat
		frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- need these two in case we reload incombat
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("ENCOUNTER_START")
		frame:RegisterEvent("ENCOUNTER_END")
		frame:UnregisterEvent("ADDON_LOADED")
		if not PotReminderDB then PotReminderDB = {} end
		for k, v in pairs(defaults) do
			if PotReminderDB[k] == nil then
				PotReminderDB[k] = v
			end
		end
		ns.version = GetAddOnMetadata(addonName, "Version")
		ns.optionsFrame = ns:_CreateOptionsPanel()
		ns.alertFrame = ns.alertFrame or ns:CreateAlertFrame()
		ns._potionchecktimer = ns.Timer:new{
			durationMillis = PotReminderDB.potcheck_delay * 1000,
			callback = ns.CheckForPotionBuff
		}
	elseif event == 'ENCOUNTER_START' then
		ns:_debugPrintf('ENCOUNTER_START')
		if PotReminderDB.pot_check then
			ns._potionchecktimer:Start(prepull_delay, 'PREPULL', ns.CheckForPotionBuff)
		end
		ns:ListenForLust(frame, true)
	elseif event == 'ENCOUNTER_END' then
		ns:_debugPrintf('ENCOUNTER_END')
		frame:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
		ns._potionchecktimer:Stop()
	elseif event == 'PLAYER_REGEN_DISABLED' then
		ns:_debugPrintf('PLAYER_REGEN_DISABLED')
		ns:ListenForLust(frame)
	elseif event == 'PLAYER_REGEN_ENABLED' then
		ns:_debugPrintf('PLAYER_REGEN_ENABLED')
		frame:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
		ns._potionchecktimer:Stop()
	elseif event == 'PLAYER_ENTERING_WORLD' then
		ns:_debugPrintf('PLAYER_ENTERING_WORLD')
		ns.difficulty = 0
		ns:UpdatePotionCooldowns()
		ns.playerName = UnitName('player')
		--if (CombatText_AddMessage == nil) then
		--	UIParentLoadAddOn("Blizzard_CombatText")
		--end
	elseif event == 'COMBAT_LOG_EVENT_UNFILTERED' then
		local _, subevent, _, _, sourceName, _, _, _, _, _, _, spellID, spellName = ...
		if subevent == 'SPELL_CAST_SUCCESS' then
			ns:RemindMeToPot(sourceName, spellID)
		end
	end
end

f:SetScript("OnEvent", FrameOnEvent)
f:RegisterEvent("ADDON_LOADED")

-- add a slash command
SLASH_POTREMINDER1 = '/pr'
local function handler(msg, editbox)
	msg = strtrim(msg)
	if msg == 'debug' then
		_debug = not _debug
	elseif msg == 'on' then
		PotReminderDB.enabled = true
		ns.optionsFrame.checkbox1:SetChecked(PotReminderDB.enabled)
	elseif msg == 'off' then
		PotReminderDB.enabled = false
		ns.optionsFrame.checkbox1:SetChecked(PotReminderDB.enabled)
	elseif msg == 'sound' then
		PotReminderDB.play_sound = not PotReminderDB.play_sound
		ns.optionsFrame.checkbox4:SetChecked(PotReminderDB.play_sound)
	elseif msg == 'test' then
		--local info = ChatTypeInfo["SYSTEM"]
		ns:UpdatePotionCooldowns()
		--UIErrorsFrame:AddMessage("HELLO WORLD", 0.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME or 5)
		if CombatText_AddMessage then
			if PotReminderDB.pot_colors then
				CombatText_AddMessage(L["MSG2"]:format("|c"..RAID_CLASS_COLORS[select(2, UnitClass('player'))].colorStr..UnitName('player')..FONT_COLOR_CODE_CLOSE), COMBAT_TEXT_SCROLL_FUNCTION, 0.0, 1.0, 0.0, "crit", nil)
			else
				CombatText_AddMessage(L["MSG2"]:format(UnitName('player')), COMBAT_TEXT_SCROLL_FUNCTION, 0.0, 1.0, 0.0, "crit", nil)
			end
		end
		ns:PlayAlert()
	else
		print(_usage)
		History()
	end
	ns:Print("is ".. (PotReminderDB.enabled and "enabled" or "disabled") ..
	". Debug is "..(_debug and "on" or "off") ..
	". Sound is "..(PotReminderDB.play_sound and "on" or "off") ..
	". Print to Chat is "..(PotReminderDB.to_chat and "on." or "off."))
end
SlashCmdList["POTREMINDER"] = handler