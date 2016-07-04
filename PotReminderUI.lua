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
	FadeOut:SetChange( -1.0 )
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
	Texture:SetTexture( [[Interface\AchievementFrame\UI-Achievement-Alert-Glow]] )
	Texture:SetBlendMode( "ADD" )
	Texture:SetTexCoord( 0, 0.78125, 0, 0.66796875 )
	Texture:SetAlpha( 0 )
	me.Glow = Texture:CreateAnimationGroup()
	me.Glow:SetLooping("REPEAT")
	local FadeIn = me.Glow:CreateAnimation( "Alpha" )
	FadeIn:SetChange( 0.7 )
	FadeIn:SetDuration( 0.5 )
	local FadeOut = me.Glow:CreateAnimation( "Alpha" )
	FadeOut:SetOrder( 2 )
	FadeOut:SetChange( -0.7 )
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
