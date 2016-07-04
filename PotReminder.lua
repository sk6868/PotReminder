local addonName, ns = ...

local L = ns.L
local f = CreateFrame("Frame", "PotReminderFrame")

local Ambiguate = Ambiguate
local UnitDebuff = UnitDebuff
local UnitExists = UnitExists
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid

local defaults = {
	enabled = true,
	lfr = true,
	normal = true,
	play_sound = false
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
ns.difficulty = 0

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

	local checkbox1 = newCheckbox(panel, "PotReminderOptionCheck1",
		L["Enable"],
		L["Toggle addon enable"],
		function(self, value) PotReminderDB.enabled = value end)
	checkbox1:SetChecked(PotReminderDB.enabled)
	checkbox1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)
	
	local checkbox2 = newCheckbox(panel, "PotReminderOptionCheck2",
		L["LFR"],
		L["Enable in LFR"],
		function(self, value) PotReminderDB.lfr = value end)
	checkbox2:SetChecked(PotReminderDB.lfr)
	checkbox2:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -46)
	
	local checkbox3 = newCheckbox(panel, "PotReminderOptionCheck3",
		L["Normal"],
		L["Enable in Normal mode"],
		function(self, value) PotReminderDB.normal = value end)
	checkbox3:SetChecked(PotReminderDB.normal)
	checkbox3:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -76)
	
	local checkbox4 = newCheckbox(panel, "PotReminderOptionCheck4",
		L["Enable Sound"],
		L["Enable Sound"],
		function(self, value) PotReminderDB.play_sound = value end)
	checkbox4:SetChecked(PotReminderDB.play_sound)
	checkbox4:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -106)
		
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
}

local SatedDebuffs = {
	80354, -- Temporal Displacement (applied by Time Warp)
	95809, -- Insanity (applied by Ancient Hysteria)
	57724, -- Sated (applied by Bloodlust)
	57723, -- Exhaustion (applied by Heroism and Drums of Fury)
}

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
		local numSlots = GetContainerNumSlots(bag)
		for i = 1, numSlots do
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

function ns:ListenForLust(eventFrame)
	self:_debugPrintf("ListenForLust")
	local isInstance, instanceType = IsInInstance()
	if PotReminderDB.enabled and isInstance and (instanceType == 'party' or instanceType == 'raid') then
		self.difficulty = select(3, GetInstanceInfo())
		local activate = true
		if self:LFR() and (not PotReminderDB.lfr) then
			activate = false
		elseif self:Normal() and (not PotReminderDB.normal) then
			activate = false
		end
		self:_debugPrintf("%s %s", tostring(activate), tostring(self:CheckIfBossEngaged()))
		if activate and self:CheckIfBossEngaged() and (not eventFrame:IsEventRegistered('COMBAT_LOG_EVENT_UNFILTERED')) then
			eventFrame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
		end
	end
end

function ns:RemindMeToPot(sourceName, spellID)
	if self:CheckforValidLust(sourceName, spellID) then
		self:_debugPrintf("RemindMeToPot(%s, %d) type(spellID)=[%s]", sourceName, spellID, type(spellID))
		if self:UpdatePotionCooldowns() then
			local msg = L["MSG1"]:format(sourceName)
			local info = ChatTypeInfo["SYSTEM"]
			self:_debugPrintf(msg)
			--UIErrorsFrame:AddMessage(msg, 1.0, 0.0, 0.0, info.id, UIERRORS_HOLD_TIME or 5)
			self:PlayAlert()
			CombatText_AddMessage(msg, COMBAT_TEXT_SCROLL_FUNCTION, 0.0, 1.0, 0.0, "crit", nil)
		else
			local msg = L["MSG2"]:format(sourceName)
			local info = ChatTypeInfo["SYSTEM"]
			self:_debugPrintf(msg)
			--UIErrorsFrame:AddMessage(msg, 0.0, 1.0, 0.0, info.id, UIERRORS_HOLD_TIME or 5)
			self:PlayAlert()
			CombatText_AddMessage(msg, COMBAT_TEXT_SCROLL_FUNCTION, 0.0, 1.0, 0.0, "crit", nil)
		end
	end
end

local function FrameOnEvent(frame, event, ...)
	local msg = ...
	if (event == 'ADDON_LOADED') and (msg == addonName) then
		frame:RegisterEvent("PLAYER_REGEN_DISABLED")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:UnregisterEvent("ADDON_LOADED")
		if not PotReminderDB then PotReminderDB = {} end
		for k, v in pairs(defaults) do
			if PotReminderDB[k] == nil then
				PotReminderDB[k] = v
			end
		end
		ns:_CreateOptionsPanel()
		ns.alertFrame = ns.alertFrame or ns:CreateAlertFrame()
	elseif event == 'PLAYER_REGEN_DISABLED' then
		ns:_debugPrintf('PLAYER_REGEN_DISABLED')
		ns:ListenForLust(frame)
	elseif event == 'PLAYER_REGEN_ENABLED' then
		ns:_debugPrintf('PLAYER_REGEN_ENABLED')
		frame:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	elseif event == 'PLAYER_ENTERING_WORLD' then
		ns:_debugPrintf('PLAYER_ENTERING_WORLD')
		ns.difficulty = 0
		ns:UpdatePotionCooldowns()
		ns.playerName = UnitName('player')
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
	elseif msg == 'off' then
		PotReminderDB.enabled = false
	elseif msg == 'sound' then
		PotReminderDB.play_sound = not PotReminderDB.play_sound
	elseif msg == 'test' then
		local info = ChatTypeInfo["SYSTEM"]
		--UIErrorsFrame:AddMessage("HELLO WORLD", 0.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME or 5)
		CombatText_AddMessage("HELLO WORLD", COMBAT_TEXT_SCROLL_FUNCTION, 0.0, 1.0, 0.0, "crit", nil)
		ns:PlayAlert()
	else
		print(_usage)
	end
	ns:Print("is ".. (PotReminderDB.enabled and "enabled" or "disabled") ..". Debug is "..(_debug and "on" or "off") ..
	". Sound is "..(PotReminderDB.play_sound and "on." or "off."))
end
SlashCmdList["POTREMINDER"] = handler