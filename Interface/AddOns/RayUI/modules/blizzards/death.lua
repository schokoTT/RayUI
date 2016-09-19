local R, L, P, G = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB, GlobalDB, GlobalDB
local B = R:GetModule("Blizzards")

function B:PLAYER_ENTERING_WORLD()
	if UnitIsDead("player") then
		StaticPopup_Show("DEATH")
	end
end


function B:FixDeathPopup()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end