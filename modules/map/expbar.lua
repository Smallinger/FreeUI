local F, C, L = unpack(select(2, ...))
local MAP = F.MAP

local format, pairs, select = string.format, pairs, select
local min, mod, floor = math.min, mod, math.floor
local MAX_REPUTATION_REACTION = MAX_REPUTATION_REACTION
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local NUM_FACTIONS_DISPLAYED = NUM_FACTIONS_DISPLAYED
local REPUTATION_PROGRESS_FORMAT = REPUTATION_PROGRESS_FORMAT
local HONOR, LEVEL, TUTORIAL_TITLE26, SPELLBOOK_AVAILABLE_AT = HONOR, LEVEL, TUTORIAL_TITLE26, SPELLBOOK_AVAILABLE_AT
local ARTIFACT_POWER, ARTIFACT_RETIRED = ARTIFACT_POWER, ARTIFACT_RETIRED

local UnitLevel, UnitXP, UnitXPMax, GetXPExhaustion, IsXPUserDisabled = UnitLevel, UnitXP, UnitXPMax, GetXPExhaustion, IsXPUserDisabled
local GetText, UnitSex, BreakUpLargeNumbers, GetNumFactions, GetFactionInfo = GetText, UnitSex, BreakUpLargeNumbers, GetNumFactions, GetFactionInfo
local GetWatchedFactionInfo, GetFriendshipReputation, GetFriendshipReputationRanks = GetWatchedFactionInfo, GetFriendshipReputation, GetFriendshipReputationRanks
local HasArtifactEquipped, ArtifactBarGetNumArtifactTraitsPurchasableFromXP = HasArtifactEquipped, ArtifactBarGetNumArtifactTraitsPurchasableFromXP
local IsWatchingHonorAsXP, UnitHonor, UnitHonorMax, UnitHonorLevel = IsWatchingHonorAsXP, UnitHonor, UnitHonorMax, UnitHonorLevel
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local C_Reputation_IsFactionParagon = C_Reputation.IsFactionParagon
local C_Reputation_GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local C_AzeriteItem_IsAzeriteItemAtMaxLevel = C_AzeriteItem.IsAzeriteItemAtMaxLevel
local C_AzeriteItem_FindActiveAzeriteItem = C_AzeriteItem.FindActiveAzeriteItem
local C_AzeriteItem_GetAzeriteItemXPInfo = C_AzeriteItem.GetAzeriteItemXPInfo
local C_AzeriteItem_GetPowerLevel = C_AzeriteItem.GetPowerLevel
local C_ArtifactUI_IsEquippedArtifactDisabled = C_ArtifactUI.IsEquippedArtifactDisabled
local C_ArtifactUI_GetEquippedArtifactInfo = C_ArtifactUI.GetEquippedArtifactInfo

local function IsAzeriteAvailable()
	local itemLocation = C_AzeriteItem_FindActiveAzeriteItem()
	return itemLocation and itemLocation:IsEquipmentSlot() and not C_AzeriteItem_IsAzeriteItemAtMaxLevel()
end

function MAP:ExpBar_Update()
	local rest = self.restBar
	if rest then
		rest:Hide()
	end

	if not IsPlayerAtEffectiveMaxLevel() then
		local xp, mxp, rxp = UnitXP('player'), UnitXPMax('player'), GetXPExhaustion()
		self:SetStatusBarColor(.29, .59, .82)
		self:SetMinMaxValues(0, mxp)
		self:SetValue(xp)
		self:Show()
		if rxp then
			rest:SetMinMaxValues(0, mxp)
			rest:SetValue(min(xp + rxp, mxp))
			rest:Show()
		end
		if IsXPUserDisabled() then
			self:SetStatusBarColor(.7, 0, 0)
		end
	elseif GetWatchedFactionInfo() then
		local _, standing, barMin, barMax, value, factionID = GetWatchedFactionInfo()
		local friendID, friendRep, _, _, _, _, _, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
		if friendID then
			if nextFriendThreshold then
				barMin, barMax, value = friendThreshold, nextFriendThreshold, friendRep
			else
				barMin, barMax, value = 0, 1, 1
			end
			standing = 5
		elseif C_Reputation_IsFactionParagon(factionID) then
			local currentValue, threshold = C_Reputation_GetFactionParagonInfo(factionID)
			currentValue = mod(currentValue, threshold)
			barMin, barMax, value = 0, threshold, currentValue
		else
			if standing == MAX_REPUTATION_REACTION then
				barMin, barMax, value = 0, 1, 1
			end
		end
		self:SetStatusBarColor(FACTION_BAR_COLORS[standing].r, FACTION_BAR_COLORS[standing].g, FACTION_BAR_COLORS[standing].b, .85)
		self:SetMinMaxValues(barMin, barMax)
		self:SetValue(value)
		self:Show()
	elseif IsWatchingHonorAsXP() then
		local current, barMax = UnitHonor('player'), UnitHonorMax('player')
		self:SetStatusBarColor(1, .24, 0)
		self:SetMinMaxValues(0, barMax)
		self:SetValue(current)
		self:Show()
	elseif IsAzeriteAvailable() then
		local azeriteItemLocation = C_AzeriteItem_FindActiveAzeriteItem()
		local xp, totalLevelXP = C_AzeriteItem_GetAzeriteItemXPInfo(azeriteItemLocation)
		self:SetStatusBarColor(.9, .8, .6)
		self:SetMinMaxValues(0, totalLevelXP)
		self:SetValue(xp)
		self:Show()
	elseif HasArtifactEquipped() then
		if C_ArtifactUI_IsEquippedArtifactDisabled() then
			self:SetStatusBarColor(.6, .6, .6)
			self:SetMinMaxValues(0, 1)
			self:SetValue(1)
		else
			local _, _, _, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI_GetEquippedArtifactInfo()
			local _, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP, artifactTier)
			xp = xpForNextPoint == 0 and 0 or xp
			self:SetStatusBarColor(.9, .8, .6)
			self:SetMinMaxValues(0, xpForNextPoint)
			self:SetValue(xp)
		end
		self:Show()
	else
		self:Hide()
	end
end

function MAP:ExpBar_UpdateTooltip()
	GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
	GameTooltip:ClearLines()
	GameTooltip:AddLine(LEVEL .. ' ' .. UnitLevel('player'), C.r, C.g, C.b)

	if not IsPlayerAtEffectiveMaxLevel() then
		GameTooltip:AddLine(' ')
		local xp, mxp, rxp = UnitXP('player'), UnitXPMax('player'), GetXPExhaustion()
		GameTooltip:AddDoubleLine(XP .. ':', BreakUpLargeNumbers(xp) .. ' / ' .. BreakUpLargeNumbers(mxp) .. ' (' .. format('%.1f%%)', xp / mxp * 100), .6, .8, 1, 1, 1, 1)
		if rxp then
			GameTooltip:AddDoubleLine(TUTORIAL_TITLE26 .. ':', '+' .. BreakUpLargeNumbers(rxp) .. ' (' .. format('%.1f%%)', rxp / mxp * 100), .6, .8, 1, 1, 1, 1)
		end
		if IsXPUserDisabled() then
			GameTooltip:AddLine('|cffff0000' .. XP .. LOCKED)
		end
	end

	if GetWatchedFactionInfo() then
		local name, standing, barMin, barMax, value, factionID = GetWatchedFactionInfo()
		local friendID, _, _, _, _, _, friendTextLevel, _, nextFriendThreshold = GetFriendshipReputation(factionID)
		local currentRank, maxRank = GetFriendshipReputationRanks(friendID)
		local colors = FACTION_BAR_COLORS[standing]
		local standingtext
		if friendID then
			if maxRank > 0 then
				name = name .. ' (' .. currentRank .. ' / ' .. maxRank .. ')'
			end
			if not nextFriendThreshold then
				value = barMax - 1
			end
			standingtext = friendTextLevel
		else
			if standing == MAX_REPUTATION_REACTION then
				barMax = barMin + 1e3
				value = barMax - 1
			end
			standingtext = GetText('FACTION_STANDING_LABEL' .. standing, UnitSex('player'))
		end
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(name, 0, .6, 1)
		GameTooltip:AddDoubleLine(standingtext, value - barMin .. ' / ' .. barMax - barMin .. ' (' .. floor((value - barMin) / (barMax - barMin) * 100) .. '%)', colors.r, colors.g, colors.b, 1, 1, 1)

		if C_Reputation_IsFactionParagon(factionID) then
			local currentValue, threshold = C_Reputation_GetFactionParagonInfo(factionID)
			local paraCount = floor(currentValue / threshold)
			currentValue = mod(currentValue, threshold)
			GameTooltip:AddDoubleLine(L['MAP_PARAGON'] .. paraCount, currentValue .. ' / ' .. threshold .. ' (' .. floor(currentValue / threshold * 100) .. '%)', .6, .8, 1, 1, 1, 1)
		end
	end

	if IsWatchingHonorAsXP() then
		local current, barMax, level = UnitHonor('player'), UnitHonorMax('player'), UnitHonorLevel('player')
		GameTooltip:AddLine(' ')
		GameTooltip:AddLine(HONOR, 0, .6, 1)
		GameTooltip:AddDoubleLine(LEVEL .. ' ' .. level, current .. ' / ' .. barMax, .8, .2, 0, 1, 1, 1)
	end

	if IsAzeriteAvailable() then
		local azeriteItemLocation = C_AzeriteItem_FindActiveAzeriteItem()
		local azeriteItem = Item:CreateFromItemLocation(azeriteItemLocation)
		local xp, totalLevelXP = C_AzeriteItem_GetAzeriteItemXPInfo(azeriteItemLocation)
		local currentLevel = C_AzeriteItem_GetPowerLevel(azeriteItemLocation)
		azeriteItem:ContinueWithCancelOnItemLoad(
			function()
				GameTooltip:AddLine(' ')
				GameTooltip:AddLine(azeriteItem:GetItemName() .. ' (' .. format(SPELLBOOK_AVAILABLE_AT, currentLevel) .. ')', 0, .6, 1)
				GameTooltip:AddDoubleLine(ARTIFACT_POWER, BreakUpLargeNumbers(xp) .. ' / ' .. BreakUpLargeNumbers(totalLevelXP) .. ' (' .. floor(xp / totalLevelXP * 100) .. '%)', .6, .8, 1, 1, 1, 1)
			end
		)
	end

	if HasArtifactEquipped() then
		local _, _, name, _, totalXP, pointsSpent, _, _, _, _, _, _, artifactTier = C_ArtifactUI_GetEquippedArtifactInfo()
		local num, xp, xpForNextPoint = ArtifactBarGetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP, artifactTier)
		GameTooltip:AddLine(' ')
		if C_ArtifactUI_IsEquippedArtifactDisabled() then
			GameTooltip:AddLine(name, 0, .6, 1)
			GameTooltip:AddLine(ARTIFACT_RETIRED, .6, .8, 1, 1)
		else
			GameTooltip:AddLine(name .. ' (' .. format(SPELLBOOK_AVAILABLE_AT, pointsSpent) .. ')', 0, .6, 1)
			local numText = num > 0 and ' (' .. num .. ')' or ''
			GameTooltip:AddDoubleLine(ARTIFACT_POWER, BreakUpLargeNumbers(totalXP) .. numText, .6, .8, 1, 1, 1, 1)
			if xpForNextPoint ~= 0 then
				local perc = ' (' .. floor(xp / xpForNextPoint * 100) .. '%)'
				GameTooltip:AddDoubleLine(L['MAP_NEXT_TRAIT'], BreakUpLargeNumbers(xp) .. ' / ' .. BreakUpLargeNumbers(xpForNextPoint) .. perc, .6, .8, 1, 1, 1, 1)
			end
		end
	end
	GameTooltip:Show()
end

function MAP:SetupScript(bar)
	bar.eventList = {
		'PLAYER_XP_UPDATE',
		'PLAYER_LEVEL_UP',
		'UPDATE_EXHAUSTION',
		'PLAYER_ENTERING_WORLD',
		'UPDATE_FACTION',
		'ARTIFACT_XP_UPDATE',
		'PLAYER_EQUIPMENT_CHANGED',
		'ENABLE_XP_GAIN',
		'DISABLE_XP_GAIN',
		'AZERITE_ITEM_EXPERIENCE_CHANGED',
		'HONOR_XP_UPDATE'
	}
	for _, event in pairs(bar.eventList) do
		bar:RegisterEvent(event)
	end
	bar:SetScript('OnEvent', MAP.ExpBar_Update)
	bar:SetScript('OnEnter', MAP.ExpBar_UpdateTooltip)
	bar:SetScript('OnLeave', F.HideTooltip)
	bar:SetScript(
		'OnMouseUp',
		function(_, btn)
			if not HasArtifactEquipped() or btn ~= 'LeftButton' then
				return
			end
			if not ArtifactFrame or not ArtifactFrame:IsShown() then
				SocketInventoryItem(16)
			else
				F:TogglePanel(ArtifactFrame)
			end
		end
	)
	hooksecurefunc(
		StatusTrackingBarManager,
		'UpdateBarsShown',
		function()
			MAP.ExpBar_Update(bar)
		end
	)
end

function MAP:ProgressBar()
	if not C.DB.map.progress_bar then
		return
	end

	local bar = CreateFrame('StatusBar', 'FreeUI_MinimapExpBar', Minimap)
	bar:SetPoint('TOPLEFT', 1, -(Minimap:GetHeight() / 8) - 1)
	bar:SetPoint('TOPRIGHT', -1, -(Minimap:GetHeight() / 8) - 1)
	bar:SetHeight(4)
	bar:SetStatusBarTexture(C.Assets.norm_tex)
	bar.bg = F.CreateBDFrame(bar, .6)

	bar:SetFrameLevel(Minimap:GetFrameLevel() + 2)

	bar:SetHitRectInsets(0, 0, 0, -10)

	local rest = CreateFrame('StatusBar', nil, bar)
	rest:SetAllPoints()
	rest:SetStatusBarTexture(C.Assets.norm_tex)
	rest:SetStatusBarColor(.34, .45, .86, .8)
	rest:SetFrameLevel(bar:GetFrameLevel() - 1)
	bar.restBar = rest

	MAP:SetupScript(bar)
end

-- Paragon reputation info
function MAP:HookParagonRep()
	local numFactions = GetNumFactions()
	local factionOffset = FauxScrollFrame_GetOffset(ReputationListScrollFrame)
	for i = 1, NUM_FACTIONS_DISPLAYED, 1 do
		local factionIndex = factionOffset + i
		local factionRow = _G['ReputationBar' .. i]
		local factionBar = _G['ReputationBar' .. i .. 'ReputationBar']
		local factionStanding = _G['ReputationBar' .. i .. 'ReputationBarFactionStanding']

		if factionIndex <= numFactions then
			local factionID = select(14, GetFactionInfo(factionIndex))
			if factionID and C_Reputation_IsFactionParagon(factionID) then
				local currentValue, threshold = C_Reputation_GetFactionParagonInfo(factionID)
				if currentValue then
					local barValue = mod(currentValue, threshold)
					local factionStandingtext = L['MAP_PARAGON'] .. floor(currentValue / threshold)

					factionBar:SetMinMaxValues(0, threshold)
					factionBar:SetValue(barValue)
					factionStanding:SetText(factionStandingtext)
					factionRow.standingText = factionStandingtext
					factionRow.rolloverText = format(REPUTATION_PROGRESS_FORMAT, BreakUpLargeNumbers(barValue), BreakUpLargeNumbers(threshold))
				end
			end
		end
	end
end

function MAP:ParagonReputationSetup()
	hooksecurefunc('ReputationFrame_Update', MAP.HookParagonRep)
end