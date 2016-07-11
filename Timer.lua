local addonName, ns = ...

local PotReminder_Timer = {
    timerFrame = CreateFrame("Frame", "PotReminder_Timer_Frame"),
    nextTimerId = 1
}

ns.Timer = PotReminder_Timer

function PotReminder_Timer:new(o)
    local newObject = {
        durationMillis = 0,
        callback = nil
    }
    if o then
        for name, value in pairs(o) do
            newObject[name] = value
        end
    end

    newObject.animationGroup = PotReminder_Timer.timerFrame:CreateAnimationGroup()
    newObject.animation = newObject.animationGroup:CreateAnimation()

    -- On timer expiration, use a closure to call the timer's callback with the timer object as the only argument
    newObject.animation:SetScript("OnFinished", function(animation, requested)
        newObject.callback(newObject)
    end)

    setmetatable(newObject, self)
    self.__index = self
    return newObject
end

function PotReminder_Timer:Start(durationMillis, flag, callback, loop)
    self:Stop()
    self.durationMillis = durationMillis
	self.flag = flag
    self.callback = callback
    self:_Start(loop)
end

function PotReminder_Timer:IsRunning()
	return self.animationGroup:IsPlaying()
end

function PotReminder_Timer:_Start(loop)
    if not self.callback then
        print("Timer missing callback")
        return
    end

    -- Per AceTimer 3.0, animations less than 100ms may fail randomly
    if not self.durationMillis or self.durationMillis < 100 then
        self.durationMillis = 100
    end
	if loop then
		self.animationGroup:SetLooping("REPEAT")
	else
		self.animationGroup:SetLooping("NONE")
	end
    self.animation:SetDuration(self.durationMillis / 1000)
    self.animationGroup:Play()
end

function PotReminder_Timer:Restart(loop)
    self:Stop()
    self:_Start(loop)
end

function PotReminder_Timer:Stop()
    self.animationGroup:Stop()
end