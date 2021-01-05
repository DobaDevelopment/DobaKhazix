-----------------------------------------------------------------------------
--[[    DOBA DEVELOPMENT, ITS MY HOBBY ENJOY    ]]
if Player.CharName ~= "Khazix" then return end
-----------------------------------------------------------------------------
--[Requirements]
require("common.log")
module("Doba Khazix", package.seeall, log.setup)
-----------------------------------------------------------------------------
--[LUA Utilities]
-----------------------------------------------------------------------------
local _SDK = _G.CoreEx
-- Libs
local TS             = _G.Libs.TargetSelector()
local Orbwalker      = _G.Libs.Orbwalker
local Spell          = _G.Libs.Spell
local Menu           = _G.Libs.NewMenu
local DmgLib         = _G.Libs.DamageLib
-- CoreEx 
local ObjManager     = _SDK.ObjectManager
local EventManager   = _SDK.EventManager
local Renderer       = _SDK.Renderer
local Enums          = _SDK.Enums
local Game           = _SDK.Game
-----------------------------------------------------------------------------
--[Variables/Tables]
-----------------------------------------------------------------------------
local Khazix = {}
local KhazixPrioHi = {}
local KhazixPrioNo = {}
-----------------------------------------------------------------------------
--[[    MENU SECTION    ]]
-----------------------------------------------------------------------------
function Khazix.LoadMenu()
        Menu.RegisterMenu("Doba Khazix", "Doba Khazix", function()
        Menu.NewTree("Combo", "Combo", function ()
            Menu.Checkbox("Combo.CastQ","Cast Q",true)
            Menu.Checkbox("Combo.CastW","Cast W",true)
            Menu.Checkbox("Combo.CastE","Cast E",true)
        end)
        Menu.NewTree("Harass", "Harass Settings", function()
            Menu.ColoredText("Mana Percentage", 0xFFFFFFFF, true)
            Menu.Slider("ManaSlider","",50,0,100)
            Menu.Checkbox("Harass.CastW",   "Use W", true)
        end)
        Menu.NewTree("KS", "Kill Secured Settings", function()
            Menu.Checkbox("KS.Q"," Use Q", true)
            Menu.Checkbox("KS.W"," Use W", true)    
            Menu.Checkbox("KS.E"," Use E", true)
        end)
        Menu.NewTree("Waveclear", "Clear", function ()
            Menu.NewTree("Lane", "Lane", function ()
                Menu.ColoredText("Mana Percentage", 0xFFFFFFFF, true)
                Menu.Slider("ManaSliderLane","",50,0,100)
                Menu.Checkbox("Lane.Q","Cast Q",true)
                Menu.Checkbox("Lane.W","Cast W",true)
                Menu.Checkbox("Lane.E","Cast E",false)
                Menu.Slider("Lane.EH","E HitCount",2,1,5)
            end)
            Menu.NewTree("Jungle", "Jungle", function ()
                Menu.ColoredText("Mana Percentage", 0xFFFFFFFF, true)
                Menu.Slider("ManaSliderJungle","",20,0,100)
                Menu.Checkbox("Jungle.Q",   "Use Q", true)
                Menu.Checkbox("Jungle.W",   "Use W", true)
                Menu.Checkbox("Jungle.E",   "Use E", false)
            end)
        end)
        Menu.NewTree("Prediction", "Prediction Settings", function()
            Menu.Slider("Chance.W","HitChance W",0.25, 0, 1, 0.05)
        end)
        Menu.NewTree("Range", "Spell Range Settings", function()
            Menu.Slider("Max.W","W Max Range", 845, 500, 1025)
            Menu.Slider("Min.W","W Min Range",50, 0, 400)
            Menu.Slider("Max.E","E Max Range", 875, 500, 875)
            Menu.Slider("Min.E","E Min Range",50, 0, 400)
        end)
        Menu.NewTree("Draw", "Drawing Settings", function()
            Menu.Checkbox("Drawing.Q.Enabled",   "Draw Q Range", false)
            Menu.ColorPicker("Drawing.Q.Color", "Draw Q Color", 0xf03030ff)
            Menu.Checkbox("Drawing.W.Enabled",   "Draw W Range", false)
            Menu.ColorPicker("Drawing.W.Color", "Draw W Color", 0x30e6f0ff)
            Menu.Checkbox("Drawing.E.Enabled",   "Draw E Range", true)
            Menu.ColorPicker("Drawing.E.Color", "Draw E Color", 0x3060f0ff)
        end)
    end)
end
-----------------------------------------------------------------------------
--[[    SPELLS SECTION   ]]
-----------------------------------------------------------------------------
local Q = Spell.Targeted({
        Slot = Enums.SpellSlots.Q,
        Range = 325,
        Delay = 0.25,
        Key = "Q",
})
local W = Spell.Skillshot({ 
        Slot = Enums.SpellSlots.W,
        Range = 1025,
        Delay = 0.25,
        Speed = 1700,
        Radius = 70,
        Collisions = { WindWall = true, Minions = true },
        Type = "Linear",
        UseHitbox = true,
        Key = "W"
})
local E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 700,
        Radius = 300,
        Type = "Circular",
        Key = "E"
})
local R = Spell.Active({
        Slot = Enums.SpellSlots.R,
        Key = "R"
})
--[[    USEFULL FUNCTION    ]]
local function GameIsAvailable()
    return
    not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling) 
end

local function GetMenuChance(spell)
    return  Menu.Get("Chance."..spell.Key)
end

local function Castable(spell,mode)
    return spell:IsReady() and Menu.Get(mode .. ".Cast"..spell.Key)
end

local function SpellTargets(spell)
    return {TS:GetTarget(spell.Range,true)}
end

local function Wave(spell)
    return Menu.Get("Lane."..spell.Key) and spell:IsReady()
end

local function Jungle(spell)
    return Menu.Get("Jungle."..spell.Key) and spell:IsReady()
end

local function KS(spell)
    return  Menu.Get("KS."..spell.Key) and spell:IsReady() 
end

function Khazix.OnNormalPriority()
    if not GameIsAvailable() then return end
    local ModeToExecute = KhazixPrioHi[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end

function Khazix.OnHighPriority()
    if not GameIsAvailable() then return end
    if Khazix.Auto() then return end
    local ModeToExecute = KhazixPrioNo[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end

local function Sdmg(spell) -- Return Spell Dmg
    local dmg = 0

    if spell.Key == "Q" then
        dmg =  (60 + (spell:GetLevel() - 1) * 25) + (1.3 * Player.BonusAD) end
    if spell.Key == "W" then
         dmg =  (85 + (spell:GetLevel() - 1) * 30) + (1 * Player.BonusAD) end
    if spell.Key == "E" then
        dmg =  (65 + (spell:GetLevel() - 1) * 35) + (0.2 * Player.BonusAD) 
    end 
    
    return dmg
end
-----------------------------------------------------------------------------
--[[    POST ATTACK JungleClear  ]]
-----------------------------------------------------------------------------
function Khazix.OnPostAttack(Target)
    if Orbwalker.GetMode() == "Waveclear" and Target.MaxHealth > 6 and Target.IsMonster then 
        if Target == nil then return end
        if Menu.Get("ManaSliderJungle") > (Player.ManaPercent * 100) then return end
        if Jungle(Q) then
            if Q:Cast(Target) then return end
        end
    end
end
-----------------------------------------------------------------------------
--[[    CHECK SPELL EVOLVE  ]]
-----------------------------------------------------------------------------
function Khazix.OnBuffGain(obj, buffInst)
    if not obj.IsMe then return end
    if buffInst.Name == "KhazixQEvo" then 
        Q.Range = 375
    end
    if buffInst.Name == "KhazixEEvo" then 
        E.Range = 900
    end
end

local function IsEvloved() --[[    IN CASE OF RELOAD  ]]
    if Q:GetName() == "KhazixQLong" then 
        Q.Range = 375
    end
    if E:GetName() == "KhazixELong" then 
        E.Range = 900
    end
end
-----------------------------------------------------------------------------
--[[    KILL STEAL SECTION  ]]
-----------------------------------------------------------------------------
function Khazix.Auto()
    if KS(Q) then
        for k,v in pairs(SpellTargets(Q)) do
            if v then
                local dmg = DmgLib.CalculatePhysicalDamage(Player,v,Sdmg(Q))
                local Ks  = Q:GetKillstealHealth(v)
                if dmg > Ks then
                    if Q:Cast(v) then return end
                end
            end
        end
    end
    if KS(W) then
        for k,v in pairs(SpellTargets(W)) do
            if v then
                local dmg = DmgLib.CalculatePhysicalDamage(Player,v,Sdmg(W))
                local Ks  = W:GetKillstealHealth(v)
                if dmg > Ks then 
                    if W:CastOnHitChance(v,Enums.HitChance.High) then return end
                end
            end
        end
    end
    if KS(E) then
        for k,v in pairs(SpellTargets(E)) do
            if v then
                local dmg = DmgLib.CalculatePhysicalDamage(Player,v,Sdmg(E))
                local Ks  = E:GetKillstealHealth(v)
                if dmg > Ks then
                    if E:CastOnHitChance(v,Enums.HitChance.High) then return end
                end
            end
        end
    end
end
-----------------------------------------------------------------------------
--[[    COMBO SECTION  ]]
-----------------------------------------------------------------------------
function KhazixPrioHi.Combo()
    local Max = Menu.Get("Max.E")
    local Min = Menu.Get("Min.E")
    if Castable(E,"Combo") then
        for k, eTarget in ipairs(SpellTargets(E)) do
            if eTarget:Distance(Player) < Max and Player:Distance(eTarget) > Min then
                if E:Cast(eTarget) then return end
            end
        end
    end
end
function KhazixPrioNo.Combo()
    local Max = Menu.Get("Max.W")
    local Min = Menu.Get("Min.W")
    if Castable(Q,"Combo") then
        for k, qTarget in pairs(SpellTargets(Q)) do
            if Q:Cast(qTarget) then
                return
            end
        end
    end
    if Castable(W,"Combo") then
        for k, wTarget in ipairs(SpellTargets(W)) do
            if wTarget:Distance(Player) < Max and Player:Distance(wTarget) > Min then 
                if W:CastOnHitChance(wTarget, GetMenuChance(W)) then return end
            end
        end
    end
end
-----------------------------------------------------------------------------
--[[    CLEAR SECTION  ]]
-----------------------------------------------------------------------------
function KhazixPrioNo.Waveclear()
    --[[    jungle clear section    ]]

    local function IsValidMinion(minion,spell)
        return minion.IsTargetable and minion.MaxHealth > 6 and spell:IsInRange(minion)
    end

    if Menu.Get("ManaSliderJungle") < (Player.ManaPercent * 100) then
        if Jungle(W) then
            for k, v in pairs(ObjManager.Get("neutral", "minions")) do
                local minion = v.AsAI
                if IsValidMinion(minion,W) then
                    if W:Cast(minion) then return end
                end
            end
        end
        if Jungle(E) then
            for k, v in pairs(ObjManager.Get("neutral", "minions")) do
                local minion = v.AsAI
                if IsValidMinion(minion,E) then
                    if E:Cast(minion) then return end
                end
            end
        end
    end

    --[[    lane clear section    ]]
    if Menu.Get("ManaSliderLane") < (Player.ManaPercent * 100) then
        if Wave(Q) then
            for k, v in pairs(ObjManager.Get("enemy", "minions")) do
            local minion = v.AsAI
                if minion then
                    if minion.IsTargetable and minion.MaxHealth > 6 and Q:IsInRange(minion) then
                        if Q:Cast(minion) then
                        return
                        end
                    end
                end
            end
        end
        if Wave(W) then
            for k, v in pairs(ObjManager.Get("enemy", "minions")) do
            local minion = v.AsAI
                if minion then
                    if minion.IsTargetable and minion.MaxHealth > 6 and W:IsInRange(minion) then
                        if W:Cast(minion) then
                        return
                        end
                    end
                end
            end
        end
        if Wave(E) then
            local EPoint = {}
            for k, v in pairs(ObjManager.Get("enemy", "minions")) do
                local minion = v.AsAI
                if IsValidMinion(minion,E) then
                    local pos = minion:FastPrediction(Game.GetLatency()+ E.Delay)
                    if pos:Distance(Player.Position) < E.Range then
                        table.insert(EPoint, pos)
                    end
                end                       
            end
            local bestPos, hitCount = E:GetBestCircularCastPos(EPoint, E.Radius)
            if bestPos and hitCount >= Menu.Get("Lane.EH") then
                E:Cast(bestPos)
            end
        end
    end
end
-----------------------------------------------------------------------------
--[[    HARASS SECTION  ]]
-----------------------------------------------------------------------------
function KhazixPrioNo.Harass()
    if Menu.Get("ManaSlider") > (Player.ManaPercent * 100) then
        return
    end
    local Ma = Menu.Get("Max.W")
    local Mi = Menu.Get("Min.W")
    if Castable(W,"Harass") then
        for k, wTarget in ipairs(SpellTargets(W)) do
            if wTarget:Distance(Player) < Ma and Player:Distance(wTarget) > Mi then 
                if W:CastOnHitChance(wTarget, GetMenuChance(W)) then return end
            end
        end
    end
end
-----------------------------------------------------------------------------
--[[    DRAWINGS SECTION  ]]
-----------------------------------------------------------------------------
function Khazix.OnDraw()
    local Pos = Player.Position
    local spells = {Q,W,E}
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..v.Key..".Enabled", true) then
            Renderer.DrawCircle3D(Pos, v.Range, 30, 3, Menu.Get("Drawing."..v.Key..".Color")) 
        end 
    end 
end
-----------------------------------------------------------------------------
function OnLoad()
    Khazix.LoadMenu()
    IsEvloved()
    for eventName, eventId in pairs(Enums.Events) do
        if Khazix[eventName] then
            EventManager.RegisterCallback(eventId, Khazix[eventName])
        end 
    end 
    return true 
end
