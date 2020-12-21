--[[    DOBA DEVELOPMENT, ITS MY HOBBY ENJOY    ]]
require("common.log")
module("Doba Khazix", package.seeall, log.setup)

if Player.CharName ~= "Khazix" then return end

local _SDK = _G.CoreEx
local Game = _SDK.Game
local Orbwalker = _G.Libs.Orbwalker
local Spell, Menu = _G.Libs.Spell, _G.Libs.NewMenu
local TS = _G.Libs.TargetSelector()
local ObjManager, EventManager = _SDK.ObjectManager, _SDK.EventManager
local Enums, Renderer =_SDK.Enums, _SDK.Renderer
local Khazix = {}

--[[    MENU SECTION    ]]
function Khazix.LoadMenu()
    Menu.RegisterMenu("Doba Khazix", "Doba Khazix", function()
	Menu.NewTree("Combo", "Combo", function ()
        Menu.Checkbox("Combo.CastQ","Cast Q",true)
        Menu.Checkbox("Combo.CastW","Cast W",true)
        Menu.Checkbox("Combo.CastE","Cast E",true)
    end)

    Menu.NewTree("Harass", "Harass Options", function()
        Menu.Checkbox("Harass.CastW",   "Use W", true)
    end)

	Menu.NewTree("Waveclear", "Clear", function ()
		Menu.ColoredText("Lane", 0xFFD700FF, true)
        Menu.Checkbox("Lane.Q","Cast Q",true)
		Menu.Checkbox("Lane.W","Cast W",true)
        Menu.Checkbox("Lane.E","Cast E",false)
        Menu.Separator()
		Menu.ColoredText("Jungle", 0xFFD700FF, true)
        Menu.Checkbox("Jungle.Q",   "Use Q", true)
        Menu.Checkbox("Jungle.W",   "Use W", true)
        Menu.Checkbox("Jungle.E",   "Use E", false)
    end)

    Menu.NewTree("Prediction", "Prediction Options", function()
        Menu.Slider("Chance.W","HitChance W",0.75, 0, 1, 0.05)
    end)

    Menu.NewTree("Range", "Spell Range Options", function()
        Menu.Slider("Max.W","W Max Range", 875, 500, 875)
        Menu.Slider("Min.W","W Min Range",50, 0, 400)
        Menu.Slider("Max.E","E Max Range", 875, 500, 875)
        Menu.Slider("Min.E","E Min Range",50, 0, 400)
    end)

    Menu.NewTree("Draw", "Drawing Options", function()
        Menu.Checkbox("Drawing.Q.Enabled",   "Draw Q Range", false)
        Menu.ColorPicker("Drawing.Q.Color", "Draw Q Color", 0xf03030ff)
        Menu.Checkbox("Drawing.W.Enabled",   "Draw W Range", false)
        Menu.ColorPicker("Drawing.W.Color", "Draw W Color", 0x30e6f0ff)
        Menu.Checkbox("Drawing.E.Enabled",   "Draw E Range", true)
        Menu.ColorPicker("Drawing.E.Color", "Draw E Color", 0x3060f0ff)
    end)
end)
end

--[[    SPELLS INFO SECTION / VIKI LOL CHAMP    ]]
local Q = Spell.Targeted({
		Slot = Enums.SpellSlots.Q,
        Range = 325,
        Delay = 0.25,
        Key = "Q"
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
        Radius = 150,
        Type = "Circular",
        Key = "E"
})
--[[    USEFULL FUNCTION    ]]
local function GameIsAvailable()--Check if Game is On
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

local lastTick = 0
function Khazix.OnTick()
    if not GameIsAvailable() then return end

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime

    if not Orbwalker.CanCast() then return end

    local ModeToExecute = Khazix[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end

function HitChance(spell)
    return Menu.Get("Chance."..spell.Key)
end

function Count(spell,team,type)
    local num = 0
    for k, v in pairs(ObjManager.Get(team, type)) do
        local minion = v.AsAI
        local Tar    = spell:IsInRange(minion) and minion.MaxHealth > 6 and minion.IsTargetable
        if minion and Tar then
            num = num + 1
        end
    end
    return num
end

function CountHeroes(Range,type)
    local num = 0
    for k, v in pairs(ObjManager.Get(type, "heroes")) do
        local hero = v.AsHero
        if hero and hero.IsTargetable and hero:Distance(Player.Position) < Range then
            num = num + 1
        end
    end
    return num
end

function CanCast(spell,mode)
    return spell:IsReady() and Menu.Get(mode .. ".Cast"..spell.Key)
end

function GetTargets(Spell)
    return {TS:GetTarget(Spell.Range,true)}
end

function Lane(spell)
    return Menu.Get("Lane."..spell.Key)
end

function Jungle(spell)
    return Menu.Get("Jungle."..spell.Key)
end
--[[    COMBO SECTION    ]]
function Khazix.ComboLogic(mode)
    local Ma = Menu.Get("Max.W")
    local Mi = Menu.Get("Min.W")
    if CanCast(Q,mode) then
        for k, qTarget in pairs(GetTargets(Q)) do
            if Q:Cast(qTarget) then
                return
            end
        end
    end
    if CanCast(W,mode) then
        for k, wTarget in ipairs(GetTargets(W)) do
            if wTarget:Distance(Player) < Ma and
             Player:Distance(wTarget) > Mi and
              W:CastOnHitChance(wTarget, HitChance(W)) then
                return
            end
        end
    end
    if CanCast(E,mode) then
        for k, eTarget in ipairs(GetTargets(E)) do
            if eTarget:Distance(Player) < Ma and
             Player:Distance(eTarget) > Mi and
              E:Cast(eTarget) then
                return
            end
        end
    end
    
end

--[[    CLEAR SECTION    ]]
function Khazix.Combo()  Khazix.ComboLogic("Combo")  end
function Khazix.WaveclearLogic()
    --[[    JUNGLE CLEAR SECTION    ]]
    if Jungle(Q) and Q:IsReady() then
        for k, v in pairs(ObjManager.Get("neutral", "minions")) do
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
    if Jungle(W) and W:IsReady() then
        for k, v in pairs(ObjManager.Get("neutral", "minions")) do
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
    if Jungle(E) and E:IsReady() then
        for k, v in pairs(ObjManager.Get("neutral", "minions")) do
          local minion = v.AsAI
            if minion then
                if minion.IsTargetable and minion.MaxHealth > 6 and E:IsInRange(minion) then
                    if E:Cast(minion) then 
                      return
                    end
                end
            end
        end
    end
--[[    LANE CLEAR SECTION    ]]
    if Lane(Q) and Q:IsReady() then
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
    if Lane(W) and W:IsReady() then
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
    if Lane(E) and E:IsReady() then
        for k, v in pairs(ObjManager.Get("enemy", "minions")) do
          local minion = v.AsAI
            if minion then
                if minion.IsTargetable and minion.MaxHealth > 6 and E:IsInRange(minion) then
                    if E:Cast(minion) then 
                      return
                    end
                end
            end
        end
    end
end

--[[    HARASS SECTION    ]]

function Khazix.HarassLogic(mode)
    local Ma = Menu.Get("Max.W")
    local Mi = Menu.Get("Min.W")
    if CanCast(W,mode) then
        for k, wTarget in ipairs(GetTargets(W)) do
            if wTarget:Distance(Player) < Ma and
             Player:Distance(wTarget) > Mi and
              W:CastOnHitChance(wTarget, HitChance(W)) then
                return
            end
        end
    end
end
function Khazix.Combo()  Khazix.ComboLogic("Combo")  end
function Khazix.Harass() Khazix.HarassLogic("Harass") end
function Khazix.Waveclear() Khazix.WaveclearLogic("Waveclear") end
--[[    DRAWINGS SECTION    ]]
function Khazix.OnDraw()
    local Pos = Player.Position
    local spells = {Q,W,E}
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..v.Key..".Enabled", true) then
            Renderer.DrawCircle3D(Pos, v.Range, 30, 3, Menu.Get("Drawing."..v.Key..".Color"))
        end
    end
end


function OnLoad()
    Khazix.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Khazix[eventName] then
            EventManager.RegisterCallback(eventId, Khazix[eventName])
        end
    end
    return true
end
