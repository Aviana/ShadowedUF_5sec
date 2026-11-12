local ShadowUF = ShadowUF
local FiveSec = {}

local function update(self, elapsed)
	local diff = 5 - (self.endTime - GetTime())
	if diff > 5 then
		self:Hide()
	else
		self:SetValue(diff)
	end
end

local function OnSizeChanged(frame)
	frame.Spark:SetSize(1,frame:GetHeight())
end

local backdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	tile = true,
	tileSize = 16,
	insets = {left = -1.5, right = -1.5, top = -1.5, bottom = -1.5},
}

ShadowUF:RegisterModule(FiveSec, "fiveSecFrame", "5 Second Rule Indicator")

function FiveSec:OnInitialize()
	ShadowUF.db.profile.units.player.fiveSecFrame = ShadowUF.db.profile.units.player.fiveSecFrame or {enabled = true}
end
FiveSec.OnProfileChange = FiveSec.OnInitialize

function FiveSec:OnConfigurationLoad()
	ShadowUF.Config.unitTable.args.bars.args.powerbar.args.fiveSecFrame = {
		type = "toggle",
		order = 2,
		name = "5 Second Rule",
		desc = "5 Second Rule Indicator on the power bar",
		arg = "fiveSecFrame.enabled",
		hidden = ShadowUF.Config.hideRestrictedOption,
		disabled = function(info)
			local unit = type(info.arg) == "number" and info[#(info) - info.arg] or info[2]
			return not ShadowUF.db.profile.units[unit].powerBar.enabled
		end,
	}
end

function FiveSec:OnEnable(frame)
	if not frame.visibility.powerBar then return end
	local _, class = UnitClass("player")
	if class == "ROGUE" or class == "WARRIOR" then
		return
	end
	
	if not frame.fiveSecFrame then
		frame.fiveSecFrame = CreateFrame("Statusbar", nil, frame)
		frame.fiveSecFrame:SetMinMaxValues(0, 5)
		frame.fiveSecFrame:SetScript("OnUpdate", update)
		frame.fiveSecFrame:SetScript("OnSizeChanged", OnSizeChanged)
		frame.fiveSecFrame:SetAllPoints(frame.powerBar)
		frame.fiveSecFrame:SetStatusBarTexture("Interface/Buttons/WHITE8X8")
		frame.fiveSecFrame:SetStatusBarColor(0, 0, 0, 0)

		frame.fiveSecFrame.endTime = 0

		frame.fiveSecFrame.Spark = CreateFrame("Frame", nil, frame.fiveSecFrame, "BackdropTemplate")
		frame.fiveSecFrame.Spark:SetBackdrop(backdrop)
		frame.fiveSecFrame.Spark:SetBackdropColor(0,0,0)
		frame.fiveSecFrame.Spark:SetPoint("TOP", frame.fiveSecFrame:GetStatusBarTexture(), "TOPRIGHT")
		frame.fiveSecFrame.Spark:SetSize(1,frame.fiveSecFrame:GetHeight())
		frame.fiveSecFrame.Spark.texture = frame.fiveSecFrame.Spark:CreateTexture(nil, "OVERLAY")
		frame.fiveSecFrame.Spark.texture:SetAllPoints(frame.fiveSecFrame.Spark)
		frame.fiveSecFrame.Spark.texture:SetTexture("Interface/Buttons/WHITE8X8")

	end
	
	frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", self, "CastSucceeded")
	if class == "DRUID" then
		frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", self, "DisplayPower")
	end
end

function FiveSec:OnDisable(frame)
	frame:UnregisterAll(self)

	if frame.fiveSecFrame then
		frame.fiveSecFrame:Hide()
	end
end

function FiveSec:OnLayoutApplied(frame)
	if not frame.fiveSecFrame or not frame.powerBar then
		if frame.fiveSecFrame then
			frame.fiveSecFrame:Hide()
		end
		return
	end
	
	frame.fiveSecFrame:SetAllPoints(frame.powerBar)
	frame.fiveSecFrame:SetFrameStrata(frame.powerBar:GetFrameStrata())
	frame.fiveSecFrame:SetFrameLevel(frame.powerBar:GetFrameLevel() + 1)
	if GetTime() >= frame.fiveSecFrame.endTime then
		frame.fiveSecFrame:Hide()
	end
end

function FiveSec:DisplayPower(frame, _, unit)
	if unit ~= "player" then return end

	if UnitPowerType(unit) == Enum.PowerType.Mana then
		frame.fiveSecFrame:Hide()
	else
		frame.fiveSecFrame:Show()
	end
end

function FiveSec:CastSucceeded(frame, event, unit, cguid, spellID)
	if unit ~= "player" then return end

	local costTable = C_Spell.GetSpellPowerCost(spellID)

	if not costTable then
		return
	end

	local hasCost = false

	for _, costInfo in ipairs(costTable) do
		if costInfo.type == Enum.PowerType.Mana and costInfo.cost and costInfo.cost > 0 then
			hasCost = true
			break
		end
	end

	if not hasCost then
		return
	end

	frame.fiveSecFrame.endTime = GetTime() + 5
	frame.fiveSecFrame:Show()
end
