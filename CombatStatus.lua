-- CombatStatus v1.9 for Runes of Magic.
-- Shows colored text: COMBAT (red) or NO COMBAT (green).
-- Left-click hides the text. Move only with Shift + left mouse drag.
-- Uses native RoM API GetPlayerCombatState().
-- This file uses ASCII only.

local CombatStatus = { version = "1.9" }
_G.CombatStatus = CombatStatus

CombatStatusSet = CombatStatusSet or {}

local ready = false
local updateElapsed = 0
local previousState = nil
local dragging = false

local defaults = {
    hasPos = false,
    hidden = false,
    posPoint = "CENTER",
    posRel = "CENTER",
    posX = 0,
    posY = 180,
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFFF00[CombatStatus]|r "..msg)
end

local function IsPlayerInCombat()
    if type(GetPlayerCombatState) == "function" then
        local ok, state = pcall(GetPlayerCombatState)
        if ok then
            return state and true or false
        end
    end
    return false
end

local function RestorePosition()
    if not CombatStatusSet.hasPos then return end
    if not CombatStatusFrame then return end

    local x = tonumber(CombatStatusSet.posX)
    local y = tonumber(CombatStatusSet.posY)

    if not x or not y then
        CombatStatusSet.hasPos = false
        return
    end

    local screenW = tonumber(GetScreenWidth()) or 1024
    local screenH = tonumber(GetScreenHeight()) or 768

    if math.abs(x) > screenW + 500 or math.abs(y) > screenH + 500 then
        CombatStatusSet.hasPos = false
        return
    end

    CombatStatusFrame:ClearAllAnchors()
    CombatStatusFrame:SetAnchor(
        CombatStatusSet.posPoint or "CENTER",
        CombatStatusSet.posRel or "CENTER",
        "UIParent",
        x,
        y
    )
end

function CombatStatus.Update(force)
    if not ready then return end

    local inCombat = IsPlayerInCombat()

    if not force and previousState == inCombat then
        return
    end

    previousState = inCombat

    if inCombat then
        CombatStatusFrame_Text:SetText("|cffff2626COMBAT|r")
    else
        CombatStatusFrame_Text:SetText("|cff26ff33NO COMBAT|r")
    end
end

function CombatStatus.PrintDebug()
    local exists = type(GetPlayerCombatState) == "function"
    local ok, state = false, nil

    if exists then
        ok, state = pcall(GetPlayerCombatState)
    end

    Print(
        "GetPlayerCombatState exists="..tostring(exists)..
        " ok="..tostring(ok)..
        " state="..tostring(state)
    )
end

function CombatStatus.OnLoad(this)
    this:RegisterEvent("VARIABLES_LOADED")
end

function CombatStatus.OnEvent(this, event)
    if event ~= "VARIABLES_LOADED" then return end
    if ready then return end

    for key, value in pairs(defaults) do
        if CombatStatusSet[key] == nil then
            CombatStatusSet[key] = value
        end
    end

    RestorePosition()

    if CombatStatusSet.hidden then
        CombatStatusFrame:Hide()
    else
        CombatStatusFrame:Show()
    end

    SaveVariablesPerCharacter("CombatStatusSet")

    ready = true
    CombatStatus.Update(true)

    Print("v"..CombatStatus.version.." loaded. LMB hides text, Shift + LMB moves it.")
end

function CombatStatus.OnUpdate(elapsedTime)
    if not ready then return end

    updateElapsed = updateElapsed + (tonumber(elapsedTime) or 0)

    if updateElapsed < 0.20 then
        return
    end

    updateElapsed = 0
    CombatStatus.Update(false)
end

function CombatStatus.OnDragStart(this)
    dragging = false

    if not IsShiftKeyDown or not IsShiftKeyDown() then
        return
    end

    dragging = true
    this:StartMoving()
end

function CombatStatus.OnDragStop(this)
    if not dragging then return end

    dragging = false
    this:StopMovingOrSizing()

    local point, relativePoint, _, x, y = this:GetAnchor()

    CombatStatusSet.posPoint = point or "CENTER"
    CombatStatusSet.posRel = relativePoint or "CENTER"
    CombatStatusSet.posX = tonumber(x) or 0
    CombatStatusSet.posY = tonumber(y) or 180
    CombatStatusSet.hasPos = true
end

function CombatStatus.OnClick(this, key)
    if key ~= "LBUTTON" then return end
    if IsShiftKeyDown and IsShiftKeyDown() then return end
    CombatStatus.Hide()
end

function CombatStatus.ResetPosition()
    CombatStatusFrame:ClearAllAnchors()
    CombatStatusFrame:SetAnchor("CENTER", "CENTER", "UIParent", 0, 180)

    CombatStatusSet.posPoint = "CENTER"
    CombatStatusSet.posRel = "CENTER"
    CombatStatusSet.posX = 0
    CombatStatusSet.posY = 180
    CombatStatusSet.hasPos = false
    CombatStatusSet.hidden = false

    CombatStatusFrame:Show()

    Print("position reset and shown.")
end

function CombatStatus.Show()
    CombatStatusFrame:Show()
    CombatStatusSet.hidden = false
    SaveVariablesPerCharacter("CombatStatusSet")
    CombatStatus.Update(true)
    Print("text shown.")
end

function CombatStatus.Hide()
    CombatStatusFrame:Hide()
    CombatStatusSet.hidden = true
    SaveVariablesPerCharacter("CombatStatusSet")
    Print("text hidden. Type /combatstatus show to bring it back.")
end

SLASH_COMBATSTATUS1 = "/combatstatus"
SLASH_COMBATSTATUS2 = "/combat"

SlashCmdList["COMBATSTATUS"] = function(msg)
    local text = tostring(msg or "")
    local command, arg = string.match(text, "^(%S*)%s*(.*)$")
    command = string.lower(command or "")

    if command == "debug" then
        CombatStatus.PrintDebug()

    elseif command == "reset" or command == "center" then
        CombatStatus.ResetPosition()

    elseif command == "show" or command == "pokaz" then
        CombatStatus.Show()

    elseif command == "hide" or command == "ukryj" then
        CombatStatus.Hide()

    elseif command == "help" or command == "pomoc" then
        Print("/combatstatus - toggle combat text")
        Print("/combatstatus reset - reset position")
        Print("/combatstatus show - show text")
        Print("/combatstatus hide - hide text")
        Print("Left-click on text - hide it")
        Print("Shift + LMB - move text")
        Print("/combatstatus debug - check combat API")

    else
        if CombatStatusFrame:IsVisible() then
            CombatStatus.Hide()
        else
            CombatStatus.Show()
        end
    end
end
