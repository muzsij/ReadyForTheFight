local addonName, addon = ...


ReadyForTheFight = {Locals = {}}

ReadyForTheFight.chatdebugmode = false;
ReadyForTheFight.debugmode = true;

local L = ReadyForTheFight.Locals

ReadyForTheFight.Boss_location = {
	["Mogu'shan Vaults"] = {
		["The Stone Guard"] = {
			["subzone"]	=	"The Golden Hall",
			["id"] = 1,
		},
		["Feng the Accursed"] = {
			["subzone"]	=	"Dais of Conquerors",
			["id"] = 2,
		},
		["Gara'jal the Spiritbinder"] = {
			["subzone"]	=	"Emperor's Reach",
			["id"] = 3,
		},
		["The Spirit Kings"]	= {
			["subzone"]	=	"The Repository",
			["id"] = 4,
		},
		["Elegon"]	= {
			["subzone"]	=	"Engine of Nalak'sha",
			["id"] = 5,
		},
		["Will of the Emperor"]	= {
			["subzone"]	=	"Forge of the Endless",
			["id"] = 6,
		}
	},
	["Heart of Fear"]	= {
		["Imperial Vizier Zor'lok"] = {
			["subzone"]	=	"Oratorium of the Voice",
			["id"] = 1,
		},
		["Blade Lord Ta'yak"] = {
			["subzone"]	=	"Training Quarters",
			["id"] = 2,
		},
		["Garalon"] = {
			["subzone"]	=	"Dread Terrace",
			["id"] = 3,
		},
		["Wind Lord Mel'jarak"] = {
			["subzone"]	=	"Staging Balcony",
			["id"] = 4,
			["needkilledid"] = 3,
		},
		["Amber-Shaper Un'sok"] = {
			["subzone"]	=	"Amber Research Sanctum",
			["id"] = 5,
		},
		["Grand Empress Shek'zeer"] = {
			["coordX"] = 0.289,
			["coordY"] = 0.738,
			["dist"] = 0.06,
			["maplevel"] = 2,
			["id"] = 6,
		},
	},
	["Terrace of Endless Spring"] = {
		["Protectors of the Endless"] = {
			["coordX"] = 0.785,
			["coordY"] = 0.487,
			["dist"] = 0.1,
			["maplevel"] = 0,
			["id"] = 1,
		},
		["Tsulong"] = {
			["coordX"] = 0.785,
			["coordY"] = 0.487,
			["dist"] = 0.1,
			["maplevel"] = 0,
			["id"] = 2,
			["needkilledid"] = 1,
		},
		["Lei Shi"] = {
			["coordX"] = 0.588,
			["coordY"] = 0.487,
			["dist"] = 0.07,
			["maplevel"] = 0,
			["id"] = 3,
		},
		["Sha of Fear"] = {
			["coordX"] = 0.39,
			["coordY"] = 0.487,
			["dist"] = 0.1,
			["maplevel"] = 0,
			["id"] = 4,
		},
	}
}
ReadyForTheFight.alertMsg = {};


local coordupdateregistered = false;
local bossfound,zonename = nil;

local frame, events = CreateFrame("Button", "RftFFrame", UIParent), {};

local update_need = false; -- ha true, akkor valtozott a helyszin es ujraellenorzes szukseges (combat eseten fordulhat elo)

function ReadyForTheFight:dbg (msg)
	if (ReadyForTheFight.debugmode) then
		print (msg);
	end
end

local function HaveGlyph(glyph) 
	local i, _, enabled, glyphSpellID;
	
	for i = 1, NUM_GLYPH_SLOTS do
		enabled, _, _, glyphSpellID = GetGlyphSocketInfo(i);
		if ( enabled ) then 
			if (glyph == GetSpellInfo( glyphSpellID ) ) then
				return true;
			end
		end
	end
	return false;
end

local function HaveTalent(talent)
	local i, _, name, selected;
	
	local activeTalentGroup = GetActiveSpecGroup() or 1;
	for i=1, GetNumTalents() do
		name, _, _, _, selected = GetTalentInfo(i,false,activeTalentGroup);
		if selected then
			if (name == talent) then
				return true;
			end
		end
	end
	return false; 
end

local function CheckTheBoss()
	if ((zonename ~= nil) and (bossfound ~= nil)) then
				if (RftFDB[zonename][bossfound]) then
					if GetSpecialization(false, false, GetActiveSpecGroup() ) then
						local spec = select(2, GetSpecializationInfo(GetSpecialization(false, false, GetActiveSpecGroup())));
						if (RftFDB[zonename][bossfound][spec]) then
							if (RftFDB[zonename][bossfound][spec]["glyph"]) then
								for k,v in pairs(RftFDB[zonename][bossfound][spec]["glyph"]) do
									if (not HaveGlyph(k)) then
										print("Missing glyph: "..k);
									end
								end
							end
							if (RftFDB[zonename][bossfound][spec]["talent"]) then
								for k,v in pairs(RftFDB[zonename][bossfound][spec]["talent"]) do
									if (not HaveTalent(k)) then
										print("Missing talent: "..k);
									end									
								end
							end
						end
					end				
				end
	end
end

function updatezoneinfo ()
	if (not InCombatLockdown()) then -- ha nincs combat, akkor mehet az ellenorzes
		zonename = GetRealZoneText();
		subzone = GetSubZoneText();
		ReadyForTheFight.alertMsg = {};
		if ((subzone == "") or (subzone == nil)) then
			subzone = zonename;
		end
		if (zonename ~= nil) then
			dbg("RealZone: ".. zonename);
		end
		if (subzone ~= nil) then
			dbg("SubZone: ".. subzone);
		end
		if ((zonename ~= nil) and (subzone ~= nil)) then -- van zonainfo
			if (RftFDB[zonename] and ReadyForTheFight.Boss_location[zonename]) then -- a zona szerepel a configban es a boss helyszinek kozott is
				if (not coordupdateregistered) then
					coordupdateregistered = true;
					frame:RegisterEvent("WORLD_MAP_UPDATE");
				end
				local bossfound = false;
				for k,v in pairs(ReadyForTheFight.Boss_location[zonename]) do
					if (not bossfound) then
						if (ReadyForTheFight.Boss_location[zonename][k]["subzone"] ~= nil) then  -- a bossnak van subzone-ja
							if (subzone == ReadyForTheFight.Boss_location[zonename][k]["subzone"]) then -- megvan a boss neve
								bossfound = k;
								ReadyForTheFight:dbg("Boss in this zone: ".. bossfound);
							end
						else -- nincs subzone
							if (ReadyForTheFight.Boss_location[zonename][k]["coordX"] ~= nil) then -- a bossnak van koordinataja
								SetMapToCurrentZone();
								local posX, posY = GetPlayerMapPosition("player");
								if ((math.abs(ReadyForTheFight.Boss_location[zonename][k]["coordX"]-posX) <= ReadyForTheFight.Boss_location[zonename][k]["dist"]) and (math.abs(ReadyForTheFight.Boss_location[zonename][k]["coordY"]-posY) <= ReadyForTheFight.Boss_location[zonename][k]["dist"]) and (select(1, GetCurrentMapDungeonLevel()) == ReadyForTheFight.Boss_location[zonename][k]["maplevel"])) then
									ReadyForTheFight:dbg("Boss in distance: ".. k);
									bossfound = k; 
								end
							end
						end
						if (bossfound) then
							if (ReadyForTheFight.Boss_location[zonename][k]["needkilledid"] ~= nil) then  -- kell-e masik bosst leolni ehhez a bosshoz
								if (not(select(3, GetInstanceLockTimeRemainingEncounter(ReadyForTheFight.Boss_location[zonename][k]["needkilledid"])))) then
									bossfound = nil;
									ReadyForTheFight:dbg("Boss is not active!");
								end
							end
						end
						if (bossfound) then
							bossalive= true;
							if (ReadyForTheFight.Boss_location[zonename][bossfound]["id"]) then
								bossalive = not (select(3, GetInstanceLockTimeRemainingEncounter(ReadyForTheFight.Boss_location[zonename][bossfound]["id"])));
							end
							if (bossalive) then
								ReadyForTheFight:dbg("Boss " .. k .. " is alive!");
	
								CheckTheBoss();
								break;
							else
								ReadyForTheFight:dbg("Boss " .. k .. " killed!");
							end
						end
					end
				end
			else
				if (coordupdateregistered) then
					frame:UnRegisterEvent("WORLD_MAP_UPDATE");
					coordupdateregistered = false;
				end

			end	
		end
		-- frissítés megvolt
		update_need = false;
	else -- combat van, ellenorzes elhalasztva a combat utan
		update_need = true;
	end
end

function events:ZONE_CHANGED(...)
	ReadyForTheFight:dbg("Event: ZONE_CHANGED"); 
	updatezoneinfo();
end

function events:ZONE_CHANGED_INDOORS(...)
	ReadyForTheFight:dbg("Event: ZONE_CHANGED_INDOORS"); 
	updatezoneinfo();
end

function events:ZONE_CHANGED_NEW_AREA(...)
	ReadyForTheFight:dbg("Event: ZONE_CHANGED_NEW_AREA"); 
	updatezoneinfo();
end

function events:ADDON_LOADED(arg1,...)
	if (arg1==addonName) then
		ReadyForTheFight:dbg("Event: ADDON_LOADED"); 
		
		if not RftFDB then 
			RftFDB = {} -- ures config
		end

		SlashCmdList["ReadyForTheFight"] = ReadyForTheFight.Options;
		
		SLASH_ReadyForTheFight1 = "/rftf"
		
		updatezoneinfo();
		
		ReadyForTheFight:CreateAlert();
	end
end

function events:PLAYER_REGEN_ENABLED(...)
	if (update_need) then -- ha combatba volt zona valtas, akkor combat utan frissitunk
		ReadyForTheFight:dbg("Update: PLAYER_REGEN_ENABLED");
		updatezoneinfo();
	end
end

function events:PLAYER_REGEN_DISABLED(...)
	ReadyForTheFight:dbg("Event: PLAYER_REGEN_DISABLED"); 
end

function events:WORLD_MAP_UPDATE(...)
	updatezoneinfo();
end

function events:ACTIVE_TALENT_GROUP_CHANGED(...)
	ReadyForTheFight:dbg("Event: ACTIVE_TALENT_GROUP_CHANGED"); 
	updatezoneinfo();
end
function events:PLAYER_ENTERING_WORLD()
	ReadyForTheFight:CreateConfig();
end

frame:SetScript("OnEvent", function(self, event, ...)
	events[event](self, ...); -- call one of the functions above
end);

frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("ZONE_CHANGED");
frame:RegisterEvent("ZONE_CHANGED_INDOORS");
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
frame:RegisterEvent("PLAYER_REGEN_DISABLED");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");

