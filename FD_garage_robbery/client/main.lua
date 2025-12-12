local garageZones = {}
local stashZones = {}
local exitZone
local currentRobbery

local function notify(opts)
  lib.notify(opts)
end

local function playEmote(name)
  if not name or name == '' then
    return false
  end

  ExecuteCommand(('e %s'):format(name))
  return true
end

local function stopEmote()
  ExecuteCommand('e c')
  ClearPedTasks(PlayerPedId())
end

local function runMinigame(kind)
  local cfg = Config.Minigame and Config.Minigame[kind]
  if not cfg or not cfg.enabled then
    return true
  end

  if cfg.mode == 'export' then
    local exp = cfg.export or {}
    if exp.resource ~= '' and exp.name ~= '' and exports[exp.resource] and exports[exp.resource][exp.name] then
      local ok = exports[exp.resource][exp.name](exp.args or {})
      if type(ok) == 'boolean' then
        return ok
      end
      return true
    else
      notify({ type = 'error', description = 'Vlastni minihra neni nastavena spravne.' })
      return false
    end
  end

  local ox = cfg.ox or {}
  if ox.type == 'circle' then
    local circle = ox.circle or {}
    local count = circle.count or 3
    local speed = circle.speed or 0.75
    local size = circle.size or 0.15
    return lib.skillCircle({ timeout = false, areaSize = size, speed = speed, count = count })
  end

  local stages = (ox and ox.stages) or { 'easy', 'easy', 'medium' }
  local inputs = (ox and ox.inputs) or { 'w', 'a', 's', 'd' }

  return lib.skillCheck(stages, inputs)
end

local function clearInteriorZones()
  if exitZone then
    exports.ox_target:removeZone(exitZone)
    exitZone = nil
  end

  for _, zoneId in pairs(stashZones) do
    exports.ox_target:removeZone(zoneId)
  end

  stashZones = {}
end

local function leaveGarage()
  if not currentRobbery then
    return
  end

  clearInteriorZones()

  local ped = PlayerPedId()
  DoScreenFadeOut(400)
  while not IsScreenFadedOut() do
    Wait(0)
  end

  local coords = currentRobbery.returnCoords
  SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
  SetEntityHeading(ped, coords.w or 0.0)
  Wait(250)
  DoScreenFadeIn(400)

  TriggerServerEvent('garageRobbery:server:finish')
  currentRobbery = nil
end

local function lootStash(index)
  if not currentRobbery or currentRobbery.looted[index] then
    notify({ type = 'inform', description = 'Toto misto uz je prazdne.' })
    return
  end

  if not runMinigame('loot') then
    notify({ type = 'error', description = 'Minihra neuspesna, zkus to znovu.' })
    return
  end

  local playedEmote = playEmote(Config.Emotes.loot)
  local success = lib.progressBar({
    duration = Config.LootTime * 1000,
    label = 'Prohledavas...',
    useWhileDead = false,
    canCancel = true,
    disable = { car = true, move = true, combat = true, mouse = false }
  })

  if playedEmote then
    stopEmote()
  end

  if not success then
    notify({ type = 'inform', description = 'Preruseno.' })
    return
  end

  local result = lib.callback.await('garageRobbery:server:loot', false, currentRobbery.garageId, index)
  if not result or not result.ok then
    notify({ type = 'error', description = result and result.reason or 'Nepodarilo se ziskat loot.' })
    return
  end

  currentRobbery.looted[index] = true

  if result.rewards and #result.rewards > 0 then
    notify({ type = 'success', description = ('Nasel jsi: %s'):format(table.concat(result.rewards, ', ')) })
  else
    notify({ type = 'inform', description = 'Nenasel jsi nic hodnotneho.' })
  end
end

local function setupInteriorZones(interior)
  for index, spot in ipairs(interior.lootSpots) do
    local zoneId = exports.ox_target:addBoxZone({
      coords = vec3(spot.x, spot.y, spot.z),
      size = vec3(0.9, 0.9, 1.8),
      rotation = spot.w or 0.0,
      debug = Config.DebugZones,
      options = {
        {
          name = ('garageRobbery:stash:%s:%s'):format(currentRobbery.garageId, index),
          icon = 'fa-solid fa-box-open',
          label = 'Prohledat uloziste',
          distance = 1.5,
          onSelect = function()
            lootStash(index)
          end
        }
      }
    })

    stashZones[index] = zoneId
  end

  exitZone = exports.ox_target:addBoxZone({
    coords = vec3(interior.exit.x, interior.exit.y, interior.exit.z),
    size = vec3(1.3, 1.3, 2.0),
    rotation = interior.exit.w or 0.0,
    debug = Config.DebugZones,
    options = {
      {
        name = ('garageRobbery:exit:%s'):format(currentRobbery.garageId),
        icon = 'fa-solid fa-door-open',
        label = 'Odejit',
        distance = 2.0,
        onSelect = leaveGarage
      }
    }
  })
end

local function enterInterior(data)
  local interior = data.interior
  if not interior then
    notify({ type = 'error', description = 'Interier neni definovan.' })
    return
  end

  currentRobbery = {
    garageId = data.garageId,
    garageLabel = data.garageLabel,
    lootType = data.lootType,
    returnCoords = data.returnCoords,
    looted = {}
  }

  local ped = PlayerPedId()
  DoScreenFadeOut(400)
  while not IsScreenFadedOut() do
    Wait(0)
  end

  SetEntityCoords(ped, interior.entry.x, interior.entry.y, interior.entry.z, false, false, false, true)
  SetEntityHeading(ped, interior.entry.w or 0.0)
  Wait(250)
  DoScreenFadeIn(400)

  setupInteriorZones(interior)
end

local function startRobbery(garage)
  if currentRobbery then
    notify({ type = 'inform', description = 'Nejdrive dokoncete aktualni loupez.' })
    return
  end

  if IsPedInAnyVehicle(PlayerPedId(), false) then
    notify({ type = 'inform', description = 'Vystup z vozidla.' })
    return
  end

  local check = lib.callback.await('garageRobbery:server:validate', false, garage.id)
  if not check or not check.ok then
    notify({ type = 'error', description = check and check.reason or 'Nelze zacit loupez.' })
    return
  end

  if not runMinigame('lockpick') then
    notify({ type = 'error', description = 'Odemknuti se nepovedlo.' })
    return
  end

  local duration = math.random(Config.BreachTime.min, Config.BreachTime.max) * 1000
  local playedEmote = playEmote(Config.Emotes.lockpick)
  local success = lib.progressBar({
    duration = duration,
    label = 'Vlamujes se do garaze...',
    useWhileDead = false,
    canCancel = true,
    disable = { car = true, move = true, combat = true, mouse = false }
  })

  if playedEmote then
    stopEmote()
  end

  if not success then
    notify({ type = 'inform', description = 'Preruseno.' })
    return
  end

  local enter = lib.callback.await('garageRobbery:server:enterGarage', false, garage.id)
  if not enter or not enter.ok then
    notify({ type = 'error', description = enter and enter.reason or 'Nepodarilo se otevrit garaz.' })
    return
  end

  enterInterior(enter)
end

local function setupGarageTargets()
  for _, garage in ipairs(Config.Garages) do
    local zoneId = exports.ox_target:addBoxZone({
      coords = garage.coords,
      size = vec3(2.4, 2.4, 2.5),
      rotation = garage.heading or 0.0,
      debug = Config.DebugZones,
      options = {
        {
          name = ('garageRobbery:%s'):format(garage.id),
          icon = 'fa-solid fa-screwdriver-wrench',
          label = ('Vloupat se do garaze (%s)'):format(garage.label or garage.id),
          distance = 2.0,
          onSelect = function()
            startRobbery(garage)
          end
        }
      }
    })

    garageZones[#garageZones + 1] = zoneId
  end
end

AddEventHandler('onResourceStop', function(resource)
  if resource ~= GetCurrentResourceName() then
    return
  end

  for _, zoneId in ipairs(garageZones) do
    exports.ox_target:removeZone(zoneId)
  end

  clearInteriorZones()
end)

CreateThread(function()
  math.randomseed(GetGameTimer())
  setupGarageTargets()
end)
