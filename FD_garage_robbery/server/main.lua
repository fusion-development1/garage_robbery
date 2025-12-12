local ESX = exports['es_extended']:getSharedObject()

local cooldowns = {} -- [garageId] = timestamp when it can be used again
local activeRobberies = {} -- [source] = { garageId = '', lootType = '', looted = {} }

math.randomseed(os.time())

local function serialiseVec4(vec)
  return { x = vec.x, y = vec.y, z = vec.z, w = vec.w or 0.0 }
end

local function serialiseInterior(interior)
  local loot = {}

  for i, spot in ipairs(interior.lootSpots or {}) do
    loot[i] = serialiseVec4(spot)
  end

  return {
    entry = serialiseVec4(interior.entry),
    exit = serialiseVec4(interior.exit),
    lootSpots = loot
  }
end

local function getGarage(id)
  for _, garage in ipairs(Config.Garages) do
    if garage.id == id then
      return garage
    end
  end
end

local function getPoliceCount()
  local total = 0

  for _, jobName in ipairs(Config.Dispatch.policeJobs or {}) do
    local players = ESX.GetExtendedPlayers('job', jobName)
    total = total + #players
  end

  return total
end

local function hasLockpick(source)
  if not Config.RequireLockpick then
    return true
  end

  local count = exports.ox_inventory:Search(source, 'count', Config.LockpickItem) or 0
  return count > 0
end

local function takeLockpick(source)
  if Config.RequireLockpick and Config.ConsumeLockpick then
    exports.ox_inventory:RemoveItem(source, Config.LockpickItem, 1)
  end
end

local function dispatchAlert(source, garage)
  local dispatched = false
  local coords = garage.coords
  local code = Config.Dispatch.code or '10-31'
  local message = (Config.Dispatch.message or 'Garage burglary in progress') .. ' - ' .. (garage.label or garage.id)

  if Config.Dispatch.system == 'cd_dispatch' and GetResourceState('cd_dispatch') == 'started' then
    TriggerEvent('cd_dispatch:AddNotification', {
      job_table = Config.Dispatch.policeJobs,
      coords = coords,
      title = code,
      message = message,
      flash = 0,
      unique_id = ('garage_%s'):format(garage.id),
      blip = {
        sprite = Config.Dispatch.blip.sprite or 357,
        scale = Config.Dispatch.blip.scale or 1.0,
        colour = Config.Dispatch.blip.color or 1,
        flashes = true,
        text = code
      }
    })

    dispatched = true
  elseif Config.Dispatch.system == 'ps-dispatch' and GetResourceState('ps-dispatch') == 'started' then
    TriggerEvent('ps-dispatch:server:notify', {
      coords = coords,
      code = code,
      message = message
    })

    dispatched = true
  elseif Config.Dispatch.system == 'custom' and Config.Dispatch.customEvent ~= '' then
    TriggerEvent(Config.Dispatch.customEvent, source, garage)
    dispatched = true
  end

  if dispatched then
    return
  end

  for _, jobName in ipairs(Config.Dispatch.policeJobs or {}) do
    for _, xPlayer in pairs(ESX.GetExtendedPlayers('job', jobName)) do
      TriggerClientEvent('ox_lib:notify', xPlayer.source, {
        title = code,
        description = message,
        type = 'inform'
      })
    end
  end
end

local function getCooldownLeft(garageId)
  local remaining = (cooldowns[garageId] or 0) - os.time()
  return remaining > 0 and remaining or 0
end

lib.callback.register('garageRobbery:server:validate', function(source, garageId)
  local garage = getGarage(garageId)
  if not garage then
    return { ok = false, reason = 'Garáž nebyla nalezena.' }
  end

  if activeRobberies[source] then
    return { ok = false, reason = 'Už se účastníš loupeže.' }
  end

  local remaining = getCooldownLeft(garageId)
  if remaining > 0 then
    return { ok = false, reason = ('Tato garáž je horká, zkus to za %ds.'):format(remaining) }
  end

  local policeRequired = garage.requiredPolice or 0
  if getPoliceCount() < policeRequired then
    return { ok = false, reason = ('Potřeba %s policistů.'):format(policeRequired) }
  end

  if not hasLockpick(source) then
    return { ok = false, reason = ('Potřebuješ %s.'):format(Config.LockpickItem) }
  end

  dispatchAlert(source, garage)

  return { ok = true, type = garage.type, label = garage.label }
end)

lib.callback.register('garageRobbery:server:enterGarage', function(source, garageId)
  local garage = getGarage(garageId)
  if not garage then
    return { ok = false, reason = 'Garáž nebyla nalezena.' }
  end

  if activeRobberies[source] then
    return { ok = false, reason = 'Dokonči aktuální loupež.' }
  end

  local remaining = getCooldownLeft(garageId)
  if remaining > 0 then
    return { ok = false, reason = ('Cooldown: %ds'):format(remaining) }
  end

  local policeRequired = garage.requiredPolice or 0
  if getPoliceCount() < policeRequired then
    return { ok = false, reason = ('Potřeba %s policistů.'):format(policeRequired) }
  end

  if not hasLockpick(source) then
    return { ok = false, reason = ('Potřebuješ %s.'):format(Config.LockpickItem) }
  end

  local interior = Config.Interiors[garage.type]
  if not interior then
    return { ok = false, reason = 'Interiér pro tento typ není nastaven.' }
  end

  takeLockpick(source)

  local cooldown = garage.cooldown or Config.BaseCooldown
  cooldowns[garageId] = os.time() + cooldown
  activeRobberies[source] = { garageId = garageId, lootType = garage.type, looted = {} }

  return {
    ok = true,
    garageId = garageId,
    garageLabel = garage.label,
    lootType = garage.type,
    interior = serialiseInterior(interior),
    returnCoords = {
      x = garage.coords.x,
      y = garage.coords.y,
      z = garage.coords.z + 0.1,
      w = garage.heading or 0.0
    }
  }
end)

lib.callback.register('garageRobbery:server:loot', function(source, garageId, index)
  local state = activeRobberies[source]
  if not state or state.garageId ~= garageId then
    return { ok = false, reason = 'Nejsi uprostřed loupeže.' }
  end

  if state.looted[index] then
    return { ok = false, reason = 'Toto místo už je prázdné.' }
  end

  local lootTable = Config.LootTables[state.lootType] or Config.LootTables.standard
  if not lootTable then
    return { ok = false, reason = 'Loot tabulka není nastavena.' }
  end

  local rewards = {}
  local xPlayer = ESX.GetPlayerFromId(source)
  if not xPlayer then
    return { ok = false, reason = 'Hráč není načten.' }
  end

  for _, item in ipairs(lootTable) do
    if math.random(100) <= (item.chance or 100) then
      local count = math.random(item.min or 1, item.max or 1)

      if count > 0 then
        if item.account then
          xPlayer.addAccountMoney(item.account, count)
          rewards[#rewards + 1] = ('%s $%s'):format(item.account, count)
        else
          local added = exports.ox_inventory:AddItem(source, item.item, count, item.metadata)

          if added then
            rewards[#rewards + 1] = ('%dx %s'):format(count, item.label or item.item)
          end
        end
      end
    end
  end

  state.looted[index] = true
  return { ok = true, rewards = rewards }
end)

RegisterNetEvent('garageRobbery:server:finish', function()
  activeRobberies[source] = nil
end)

AddEventHandler('playerDropped', function()
  activeRobberies[source] = nil
end)
