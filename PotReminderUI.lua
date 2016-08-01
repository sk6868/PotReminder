local addonName, ns = ...

local L = ns.L

local iconPotion = nil -- icon for shared potions cooldown
--local iconElixir = nil -- icon for shared elixirs cooldown

-- Cache icons for special purposes such as shared cooldowns
local function InitializeIcons()
	iconPotion = GetItemIcon(109219) -- icon for shared potions cooldown
	--iconElixir = GetItemIcon(28104) -- icon for shared elixirs cooldown
end

function ns:CreateAlertFrame()
	InitializeIcons()
	local frame = CreateFrame("Frame", "PotReminderAlertFrame")
	frame:SetSize(48,48)
	frame:SetPoint("CENTER", WorldFrame, "CENTER", 0, -30)
	frame.tex = frame:CreateTexture(nil, "BACKGROUND")
	frame.tex:SetAllPoints()
	frame.tex:SetTexture(iconPotion)
	frame.tex:SetAlpha(0.85)
	
	frame.FadeOut = frame.tex:CreateAnimationGroup()
	local FadeOut = frame.FadeOut:CreateAnimation( "Alpha" )
	--FadeOut:SetChange( -1.0 )
	FadeOut:SetFromAlpha(1)
	FadeOut:SetToAlpha(0)
	FadeOut:SetDuration( 2.0 )
	FadeOut:SetScript("OnFinished", function(self) frame:Hide() end)
	
	self:CreateGlow(frame)
	frame:Hide()
	return frame
end

function ns:HideAlertFrame()
	if self.alertFrame then self.alertFrame:Hide() end
end

local loops = 0
local play_sound = true

function ns:CreateGlow(me)
	-- Glow animation
	local Texture = me:CreateTexture( nil, "OVERLAY" )
	Texture:SetPoint( "CENTER", me )
	Texture:SetSize( 400 / 300 * me:GetWidth(), 171 / 70 * me:GetHeight() )
	--Texture:SetTexture( [[Interface\AchievementFrame\UI-Achievement-Alert-Glow]] )
	Texture:SetTexture(235399) -- "Interface/AchievementFrame/UI-Achievement-Alert-Glow"
	Texture:SetBlendMode( "ADD" )
	Texture:SetTexCoord( 0, 0.78125, 0, 0.66796875 )
	Texture:SetAlpha( 0 )
	me.Glow = Texture:CreateAnimationGroup()
	me.Glow:SetLooping("REPEAT")
	local FadeIn = me.Glow:CreateAnimation( "Alpha" )
	--FadeIn:SetChange( 0.7 )
	FadeIn:SetFromAlpha(0)
	FadeIn:SetToAlpha(0.7)
	FadeIn:SetDuration( 0.5 )
	local FadeOut = me.Glow:CreateAnimation( "Alpha" )
	FadeOut:SetOrder( 2 )
	--FadeOut:SetChange( -0.7 )
	FadeOut:SetFromAlpha(0.7)
	FadeOut:SetToAlpha(0)
	FadeOut:SetDuration( 1.5 )
	
	me.Glow:SetScript("OnPlay", function(animGroup) me.FadeOut:Stop() end)
	
	me.Glow:SetScript("OnLoop", function(animGroup, state)
		loops = loops + 1
		if loops == 1 then
			loops = 0
			animGroup:Finish()
		end
	end)
	
	me.Glow:SetScript("OnFinished", function(animGroup, requested)
		if me and me.FadeOut then me.FadeOut:Play() end
	end)
end

function ns:PlayAlert()
	self.alertFrame:Show()
	self.alertFrame.Glow:Stop()
	if PotReminderDB.play_sound then
		PlaySoundFile("Interface\\AddOns\\PotReminder\\tmasti01.ogg", "Master")
	end
	self.alertFrame.Glow:Play()
end

function ns:CreateSlider(parent, name, desc, minval, maxval, width, height, stepvalue, defval)
	local slider = CreateFrame('Slider', name, parent, 'OptionsSliderTemplate')
	_G[name..'Low']:SetText(minval)
	_G[name..'High']:SetText(maxval)
	_G[name..'Text']:SetText(desc)
	
	slider:ClearAllPoints()
	slider:SetOrientation("HORIZONTAL")
	slider:SetMinMaxValues(minval, maxval)
	slider:SetValue(defval)
	slider:SetSize(width, height)
	slider:SetValueStep(stepvalue)
	slider:EnableMouseWheel(true)
	slider:SetObeyStepOnDrag(true)
	
	slider.EditBox = self:CreateSliderEditBox(slider) -- must come after slider:SetValue
	slider.EditBox:SetCursorPosition(0)
	
	slider:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true,
		edgeSize = 8,
		tileSize = 8,
		insets = {left = 3, right = 3, top = 6, bottom = 6}
	})
	slider:SetBackdropBorderColor(0.7, 0.7, 0.7, 1.0)
	slider:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(1, 1, 1, 1)
	end)
	slider:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(0.7, 0.7, 0.7, 1.0)
	end)
	slider:SetScript("OnMouseWheel", function(self, delta)
		if delta > 0 then
			self:SetValue(self:GetValue() + self:GetValueStep())
		else
			self:SetValue(self:GetValue() - self:GetValueStep())
		end
	end)
	slider:SetScript("OnValueChanged", function(self, value)
		slider.EditBox:SetText(value)
		PotReminderDB.potcheck_delay = value
	end)

	return slider
end

function ns:CreateSliderEditBox(slider)
	local editbox = CreateFrame("EditBox", nil, slider)
	editbox:EnableMouseWheel(true)
	editbox:SetAutoFocus(false)
	editbox:SetNumeric(true)
	editbox:SetJustifyH("Center")
	editbox:SetFontObject(GameFontHighlightSmall)
	editbox:SetSize(50, 14)
	editbox:SetPoint("Top", slider, "Bottom", 0, -1)
	editbox:SetTextInsets(4, 4, 0, 0)
	editbox:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true,
		edgeSize = 1,
		tileSize = 5
	})
	editbox:SetBackdropColor(0, 0, 0, 1)
	editbox:SetBackdropBorderColor(0.2, 0.2, 0.2, 1.0)
	editbox:SetText(slider:GetValue())
	--[[editbox:SetScript("OnShow", function(self)
	self:SetText("")
	self:SetText(slider:GetValue())
	end)]]
	if InterfaceOptionsFrame then
		InterfaceOptionsFrame:HookScript("OnShow", function(self)
			--editbox:SetText("")
			editbox:SetText(slider:GetValue())
		end)
	end
	editbox:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
	end)
	editbox:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1.0)
	end)
	editbox:SetScript("OnMouseWheel", function(self, delta)
		if delta > 0 then
			slider:SetValue(slider:GetValue() + slider:GetValueStep())
		else
			slider:SetValue(slider:GetValue() - slider:GetValueStep())
		end
	end)
	editbox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	editbox:SetScript("OnEnterPressed", function(self)
		local value = tonumber(self:GetText())
		if value then
			local min, max = slider:GetMinMaxValues()
			if value >= min and value <= max then
				slider:SetValue(value)
			elseif value < min then
				slider:SetValue(min)
			elseif value > max then
				slider:SetValue(max)
			end
			editbox:SetText(slider:GetValue())
		else
			slider:SetValue(slider:GetValue())
		end
		self:ClearFocus()
	end)
	editbox:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
	end)
	editbox:SetScript("OnEditFocusGained", function(self)
		self:HighlightText(0, -1)
	end)
	return editbox
end