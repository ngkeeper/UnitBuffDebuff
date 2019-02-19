local refresh = 4		-- refresh rate, Hz
local maxAura = 40		-- WOW API specifies maximum buff / debuff to be 40
local maxAuraDisplay = 40

local buff = {}
local debuff = {}
local icons = {}

local enabled = true	
local lastRefresh = GetTime()

function auraClear(auras)
	for i, v in ipairs(auras) do auras[i] = nil end
end
function auraSort(auras)
	table.sort(auras, function(a,b) 
		return ( a.id < b.id ) or ( a.id == b.id ) and ( a.expiration < b.expiration )
	end)
end
function auraShow(auras)
	local lastIcon = 0
	if auras then 
		if enabled then 
			for i, v in ipairs(auras) do 
				icons[i].texture:SetTexture(GetSpellTexture(v.id))
				if i <= maxAuraDisplay then 
					icons[i]:Show()
					lastIcon = i
				end
			end
		end
	end
	
	for i = lastIcon + 1, maxAura do 
		if icons[i] then 
			icons[i]:Hide()
		end
	end
end
function updateBuff(target, minDuration, maxDuration)
	target = target or "player"
	
	minDuration = minDuration or -1
	maxDuration = maxDuration or 7200
	
	auraClear(buff)
	for i = 1, maxAura do
		local ub_name, _, ub_stack, _, ub_duration, ub_expiration, _, _, _, ub_spell_id = UnitBuff(target, i)
		if ub_name then 
			if ub_duration >= minDuration and ub_duration <= maxDuration then 
				local aBuff = {}
				aBuff.id = ub_spell_id
				aBuff.duration = ub_duration
				aBuff.expiration = ub_expiration
				aBuff.stack = ub_stack
				table.insert(buff, aBuff)
			end
		end
	end
	auraSort(buff)
end
function updateDebuff(target, minDuration, maxDuration)
	target = target or "player"
	
	minDuration = minDuration or -1
	maxDuration = maxDuration or 7200
	
	auraClear(debuff)
	for i = 1, maxAura do
		local ud_name, _, ud_stack, _, ud_duration, ud_expiration, _, _, _, ud_spell_id = UnitDebuff("target", i)
		if ud_name then
			if ud_duration >= minDuration and ud_duration <= maxDuration then 
				local aDebuff = {}
				aDebuff.id = ud_spell_id
				aDebuff.duration = ud_duration
				aDebuff.expiration = ud_expiration
				aDebuff.stack = ud_stack
				table.insert(debuff, aDebuff)
			end
		end
	end
	auraSort(debuff)
end

SLASH_UBD1 = "/ubd"
SLASH_UBD1 = "/udb"

SlashCmdList.UBD = function(msg)
	if msg == "" then 
		enabled = not(enabled)
	end
	local args = {}
	for v in msg:gmatch("%S+") do 
		table.insert(args, v)
	end
	if args[1] == "scale" then
		CONFIG.scale = tonumber(args[2]) or CONFIG.scale
		updateIcons()
	end
	if args[1] == "position" or args[1] == "pos" then
		CONFIG.x = tonumber(args[2]) or CONFIG.x
		CONFIG.y = tonumber(args[3]) or CONFIG.y
		updateIcons()
	end
	if args[1] == "grow" then
		local xGrow = tonumber(args[2]) or CONFIG.xGrow
		local yGrow = tonumber(args[3]) or CONFIG.yGrow
		
		CONFIG.xGrow = xGrow < 0 and -1 or 1 
		CONFIG.yGrow = yGrow < 0 and -1 or 1 
		updateIcons()
	end
	if args[1] == "max" then
		local xMax = tonumber(args[2]) or CONFIG.xMax
		local yMax = tonumber(args[3]) or CONFIG.yMax
		
		CONFIG.xMax = xMax > 0 and 1 or -1 
		CONFIG.yMax = yMax > 0 and 1 or -1 
		updateIcons()
	end
end

function updateIcons()
	for i, v in ipairs(icons) do
		local x = ( ( i - 1 ) % CONFIG.xMax ) * 31 * CONFIG.xGrow * CONFIG.scale + CONFIG.x
		local y = math.floor( ( i - 1 ) / CONFIG.xMax ) * 31 * CONFIG.yGrow * CONFIG.scale + CONFIG.y
		v:SetWidth(30 * CONFIG.scale)
		v:SetHeight(30 * CONFIG.scale)
		v:SetPoint("CENTER", x, y)
	end
end
	
local fInit = CreateFrame("Frame")
fInit:RegisterEvent("PLAYER_ENTERING_WORLD")
fInit:SetScript("OnEvent", function(self, event, ...)
	CONFIG = CONFIG or {}
	--CONFIG = {}
	CONFIG.x = CONFIG.x or 0
	CONFIG.y = CONFIG.y or 0
	CONFIG.xGrow = CONFIG.xGrow or 1	-- 1 or -1
	CONFIG.yGrow = CONFIG.yGrow or 1	-- 1 or -1
	
	CONFIG.xMax = CONFIG.xMax or 8
	CONFIG.yMax = CONFIG.yMax or 5
	
	CONFIG.scale = CONFIG.scale or 1
	
	maxAuraDisplay = math.floor(math.min(maxAura, CONFIG.xMax * CONFIG.yMax) + 0.5)
	
	for i = 1, maxAura do 
		icons[i] = CreateFrame("Frame",nil,UIParent)
		icons[i]:SetFrameStrata("BACKGROUND")
		icons[i]:SetWidth(30 * CONFIG.scale)
		icons[i]:SetHeight(30 * CONFIG.scale)
		local x = ( ( i - 1 ) % CONFIG.xMax ) * 31 * CONFIG.xGrow * CONFIG.scale + CONFIG.x
		local y = math.floor( ( i - 1 ) / CONFIG.xMax ) * 31 * CONFIG.yGrow * CONFIG.scale + CONFIG.y
		icons[i]:SetPoint("CENTER", x, y)
		
		local t = icons[i]:CreateTexture(nil,"BACKGROUND")
		t:SetAllPoints(icons[i])
		icons[i].texture = t;
	end
end)

local fUpdate = CreateFrame("Frame")
fUpdate:SetScript("OnUpdate", function(self, ...)
	local timestamp = GetTime()
	if timestamp - lastRefresh > 1 / refresh then 
		if UnitCanAssist("player", "target") then 
			updateBuff("target", 2.5, 40)
			auraShow(buff)
		elseif UnitCanAttack("player", "target") then 
			updateDebuff("target", 2.5, 40)
			auraShow(debuff)
		else
			auraShow()
		end
		lastRefresh = timestamp
	end
end)

