local utils = {}

local GetWorldCoordFromScreenCoord = GetWorldCoordFromScreenCoord
local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial

---@param flag number
---@return boolean hit
---@return number entityHit
---@return vector3 endCoords
---@return vector3 surfaceNormal
---@return number materialHash
function utils.raycastFromCamera(flag)
    local coords, normal = GetWorldCoordFromScreenCoord(0.5, 0.5)
    local destination = coords + normal * 10
    local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z,
        flag, cache.ped, 4)

    while true do
        Wait(0)
        local retval, hit, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultIncludingMaterial(handle)

        if retval ~= 1 then
            ---@diagnostic disable-next-line: return-type-mismatch
            return hit, entityHit, endCoords, surfaceNormal, materialHash
        end
    end
end

function utils.getTexture()
    return lib.requestStreamedTextureDict('shared'), 'emptydot_32'
end

-- SetDrawOrigin is limited to 32 calls per frame. Set as 0 to disable.
local drawZoneSprites = GetConvarInt('ox_target:drawSprite', 24)
local enableObjectSprites = GetConvarInt('ox_target:enableObjectSprite', 1) == 1
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local colour = vector(255, 255, 255, 175)
local hover = vector(135, 218, 33, 175)
local currentZones = {}
local previousZones = {}
local drawZones = {}
local drawN = 0
local width = 0.02
local height = width * GetAspectRatio(false)
local maxDist = 14
local checkLos = GetConvarInt('ox_target:checkLOS', 1) == 1
local entityRefresh = 300

if drawZoneSprites == 0 then drawZoneSprites = -1 end

local lastRefresh = GetGameTimer() - 1001
local closestEntities = {}
local function refreshEntities()
    if GetGameTimer() - lastRefresh < entityRefresh then
        return
    end
    closestEntities = {}
    local objects = GetGamePool("CObject")
    local peds = GetGamePool("CPed")
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local coords
    local index = 0
    for k, v in ipairs(objects) do
        index += 1
        coords = GetEntityCoords(v)
        closestEntities[index] = {
            coords = coords,
            distance = #(coords - playerCoords),
            entity = v
        }
    end
    for k, v in ipairs(peds) do
        index += 1
        coords = GetEntityCoords(v)
        closestEntities[index] = {
            coords = coords,
            distance = #(coords - playerCoords),
            entity = v
        }
    end
    table.sort(closestEntities, function(a, b) return a.distance < b.distance end)
    for k, v in ipairs(closestEntities) do
        if v.distance >= maxDist then
            return
        end
        v.netId = NetworkGetEntityIsNetworked(v.entity) and NetworkGetNetworkIdFromEntity(v.entity)
        v.model = GetEntityModel(v.entity)
        v.visible = (not checkLos) or (HasEntityClearLosToEntity(playerPed, v.entity, 17))
    end
end

local api
local viableObjects = {}
function utils.refreshObjectSprites()
    if not enableObjectSprites then return end
    -- sorry, this is what backwards compability does to the performance
    refreshEntities()
    if not api then
        api = require 'client.api'
    end
    local models = api.getModels()
    if not models then models = {} end

    local localEntities, entities = api.getEntities()
    if not localEntities then localEntities = {} end
    if not entities then entities = {} end

    viableObjects = {}

    for k, v in ipairs(closestEntities) do
        if v.distance >= maxDist then break end
        local isViable = (models[v.model] or localEntities[v.entity] or (v.netId and entities[v.netId]))
        if not isViable or not v.visible then
            goto continue
        end

        local contains = currentTarget?.entity == v.entity
        viableObjects[#viableObjects+1] =  { entity = v.entity, coords = v.coords, colour = contains and hover or nil }
        ::continue::
    end
end

---@param coords vector3
---@return CZone[], boolean
function utils.getNearbyZones(coords)
    if not Zones then return currentZones, false end

    local n = 0
    drawN = 0
    previousZones, currentZones = currentZones, table.wipe(previousZones)

    for _, zone in pairs(Zones) do
        local contains = zone:contains(coords)

        if contains then
            n += 1
            currentZones[n] = zone
        end

        if drawN <= drawZoneSprites and zone.drawSprite ~= false and (contains or (zone.distance or maxDist) < maxDist) then
            drawN += 1
            drawZones[drawN] = zone
            zone.colour = contains and hover or nil
        end
    end

    local previousN = #previousZones

    if n ~= previousN then
        return currentZones, true
    end

    if n > 0 then
        for i = 1, n do
            local zoneA = currentZones[i]
            local found = false

            for j = 1, previousN do
                local zoneB = previousZones[j]

                if zoneA == zoneB then
                    found = true
                    break
                end
            end

            if not found then
                return currentZones, true
            end
        end
    end

    return currentZones, false
end

function utils.drawZoneSprites(dict, texture)
    if drawN == 0 then return end

    for i = 1, drawN do
        local zone = drawZones[i]
        local spriteColour = zone.colour or colour

        if zone.drawSprite ~= false then
            SetDrawOrigin(zone.coords.x, zone.coords.y, zone.coords.z)
            DrawSprite(dict, texture, 0, 0, width, height, 0, spriteColour.r, spriteColour.g, spriteColour.b,
                spriteColour.a)
        end
    end

    if drawN < drawZoneSprites then
        for i=1, drawZoneSprites-1 do
            local obj = viableObjects[i]
            if not obj then break end
            local spriteColour = obj.colour or colour
            if currentTarget?.entity == obj.entity then
                spriteColour = hover
            end
            SetDrawOrigin(obj.coords.x, obj.coords.y, obj.coords.z)
            DrawSprite(dict, texture, 0, 0, width, height, 0, spriteColour.r, spriteColour.g, spriteColour.b,
                spriteColour.a)
        end
    end

    ClearDrawOrigin()
end

function utils.hasExport(export)
    local resource, exportName = string.strsplit('.', export)

    return pcall(function()
        return exports[resource][exportName]
    end)
end

local playerItems = {}

function utils.getItems()
    return playerItems
end

---@param filter string | string[] | table<string, number>
---@param hasAny boolean?
---@return boolean
function utils.hasPlayerGotItems(filter, hasAny)
    playerItems = utils.getItems()

    local _type = type(filter)

    if _type == 'string' then
        return (playerItems[filter] or 0) > 0
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, amount in pairs(filter) do
                local hasItem = (playerItems[name] or 0) >= amount

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local hasItem = (playerItems[type(filter[i]) == "table" and filter[i].item or filter[i]] or 0) > 0

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        end
    end

    return not hasAny
end

if OM.Framework == "qb" then

    local QBCore = exports['qb-core']:GetCoreObject()

    local success, result = pcall(function()
        return QBCore.Functions.GetPlayerData()
    end)

    local playerData = success and result or {}
    local playerItems = utils.getItems()

    local function setPlayerItems()
        if not playerData or not playerData.items then return end

        table.wipe(playerItems)

        for _, item in pairs(playerData.items) do
            playerItems[item.name] = (playerItems[item.name] or 0) + (item.amount or 0)
        end
    end

    local usingOxInventory = utils.hasExport('ox_inventory.Items')

    if not usingOxInventory then
        setPlayerItems()
    end

    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        playerData = QBCore.Functions.GetPlayerData()
        if not usingOxInventory then setPlayerItems() end
    end)

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
        if source == '' then return end

        playerData = val

        if not usingOxInventory then setPlayerItems() end
    end)
    function utils.hasPlayerGotGroup(filter)
        local _type = type(filter)

    if _type == 'string' then

        if playerData.job.name == filter or playerData.gang.name == filter or playerData.citizenid == filter then
            return true
        end
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, grade in pairs(filter) do

                if playerData.job.name == name and grade <= playerData.job.grade.level or playerData.gang.name == name and grade <= playerData.gang.grade.level or playerData.citizenid == name then
                    return true
                else
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local name = filter[i]
                local job = playerData.job.name == name
                local gang = playerData.gang.name == name
                local citizenId = playerData.citizenid == name

                if job or gang or citizenId then
                    return true
                else
                    return false
                end
            end
        end
    end
    end
elseif OM.Framework == "esx" then

local ESX = exports.es_extended:getSharedObject()
local groups = { 'job', 'job2' }
local playerGroups = {}
local playerItems = utils.getItems()
local usingOxInventory = utils.hasExport('ox_inventory.Items')

local function setPlayerData(playerData)
    table.wipe(playerGroups)
    table.wipe(playerItems)

    for i = 1, #groups do
        local group = groups[i]
        local data = playerData[group]

        if data then
            playerGroups[group] = data
        end
    end

    if usingOxInventory or not playerData.inventory then return end

    for _, v in pairs(playerData.inventory) do
        if v.count > 0 then
            playerItems[v.name] = v.count
        end
    end
end

if ESX.PlayerLoaded then
    setPlayerData(ESX.PlayerData)
end

RegisterNetEvent('esx:playerLoaded', function(data)
    if source == '' then return end
    setPlayerData(data)
end)

RegisterNetEvent('esx:setJob', function(job)
    if source == '' then return end
    playerGroups.job = job
end)

RegisterNetEvent('esx:setJob2', function(job)
    if source == '' then return end
    playerGroups.job2 = job
end)

RegisterNetEvent('esx:addInventoryItem', function(name, count)
    playerItems[name] = count
end)

RegisterNetEvent('esx:removeInventoryItem', function(name, count)
    playerItems[name] = count
end)

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasPlayerGotGroup(filter)
    local _type = type(filter)
    for i = 1, #groups do
        local group = groups[i]

        if _type == 'string' then
            local data = playerGroups[group]

            if filter == data?.name then
                return true
            end
        elseif _type == 'table' then
            local tabletype = table.type(filter)

            if tabletype == 'hash' then
                for name, grade in pairs(filter) do
                    local data = playerGroups[group]

                    if data?.name == name and grade <= data.grade then
                        return true
                    end
                end
            elseif tabletype == 'array' then
                for j = 1, #filter do
                    local name = filter[j]
                    local data = playerGroups[group]

                    if data?.name == name then
                        return true
                    end
                end
            end
        end
    end
end
else if OM.Framework == "ox" then
    local playerGroups = exports.ox_core.GetPlayerData()?.groups or {}

    AddEventHandler('ox:playerLoaded', function(data)
        playerGroups = data.groups
    end)
    
    RegisterNetEvent('ox:setGroup', function(name, grade)
        if source == '' then return end
        playerGroups[name] = grade
    end)
    
    ---@diagnostic disable-next-line: duplicate-set-field
    function utils.hasPlayerGotGroup(filter)
        local _type = type(filter)
    
        if _type == 'string' then
            local grade = playerGroups[filter]
    
            if grade then
                return true
            end
        elseif _type == 'table' then
            local tabletype = table.type(filter)
    
            if tabletype == 'hash' then
                for name, grade in pairs(filter) do
                    local playerGrade = playerGroups[name]
    
                    if playerGrade and grade <= playerGrade then
                        return true
                    end
                end
            elseif tabletype == 'array' then
                for i = 1, #filter do
                    local name = filter[i]
                    local grade = playerGroups[name]
    
                    if grade then
                        return true
                    end
                end
            end
        end
    end
    
else if OM.Framework == "nd" then
    local NDCore = exports["ND_Core"]

    local playerGroups = NDCore:getPlayer()?.groups or {}
    
    RegisterNetEvent("ND:characterLoaded", function(data)
        playerGroups = data.groups
    end)
    
    RegisterNetEvent("ND:updateCharacter", function(data)
        if source == '' then return end
        playerGroups = data.groups or {}
    end)
    
    ---@diagnostic disable-next-line: duplicate-set-field
    function utils.hasPlayerGotGroup(filter)
        local _type = type(filter)
    
        if _type == 'string' then
            local group = playerGroups[filter]
    
            if group then
                return true
            end
        elseif _type == 'table' then
            local tabletype = table.type(filter)
    
            if tabletype == 'hash' then
                for name, grade in pairs(filter) do
                    local playerGrade = playerGroups[name]?.rank
    
                    if playerGrade and grade <= playerGrade then
                        return true
                    end
                end
            elseif tabletype == 'array' then
                for i = 1, #filter do
                    local name = filter[i]
                    local group = playerGroups[name]
    
                    if group then
                        return true
                    end
                end
            end
        end
    end
end
end
end

-- function utils.hasPlayerGotGroup(filter)
--     if OM.Framework == "esx" then
--         utils.hasPlayerGotGroup(filter)
--     elseif OM.Framework == "qb" then
--         utilsQB.hasPlayerGotGroup(filter)
--     end
-- end

function utils.warn(msg)
    local trace = Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())
    local _, _, src = string.strsplit('\n', trace, 4)

    warn(('%s ^0%s\n'):format(msg, src:gsub(".-%(", '(')))
end

return utils
