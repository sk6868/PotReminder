local _, ns = ...
---------------------------------------------------------------------------
--  Localization START
---------------------------------------------------------------------------
ns.L = ns.L or setmetatable({}, {
	__index = function(t, k)
				rawset(t, k, k)
				return k
			end,
	__newindex = function(t, k, v)
					if v == true then
						rawset(t, k, k)
					else
						rawset(t, k, v)
					end
				end,
})

function ns:RegisterLocale(locale, tbl)
	if locale == "enUS" or locale == GetLocale() then
		for k,v in pairs(tbl) do
			if v == true then
				self.L[k] = k
			elseif type(v) == "string" then
				self.L[k] = v
			else
				self.L[k] = k
			end
		end
	end
end
---------------------------------------------------------------------------
--  Localization END
---------------------------------------------------------------------------

local translations = {
	["Pot Reminder"] 				= "Pot Reminder",
	["Enable"]						= "Toggle Pot Reminder on/off",
	["Toggle addon enable"]			= true,
	["LFR"]							= true,
	["Enable in LFR"]				= true,
	["Normal"]						= true,
	["Enable in Normal mode"]		= true,
	["Enable Sound"]				= true,
	["ChatAlert"]					= "Print to Chat",
	["Alert to chat"]				= "Print alert to chat",
	["PotCheck"]					= "Check for potion",
	["Check for lust pot"]			= "Check if potion used after lust",
	["ClassColors"]					= "Class Colors",
	["Show class colors"]			= "Show class colorized names",
	["SendtoChat"]					= "Potion check to chat",
	["Send to RW or Raid chat"]		= "Send potion check results to raid warning or raid chat",
	["MSG0"]						= "[No potion after %.2f seconds]: %s",
	["MSG1"]						= "[%s] LUSTED! BUT POTIONS ARE IN COOLDOWN :(",
	["MSG2"]						= "[%s] LUSTED! DRINK YOUR POTION!",
	["NONE"]						= "none",
	["General Options"]				= true,
	["Seconds after lust to check"] = true,
}

ns:RegisterLocale("enUS", translations)
translations = nil