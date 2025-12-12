Config = {}

-- Debug settings
Config.DebugZones = false

-- Lockpick and timing setup
Config.RequireLockpick = true
Config.ConsumeLockpick = true
Config.LockpickItem = 'lockpick'
Config.BreachTime = { min = 45, max = 60 } -- seconds for the main break-in
Config.LootTime = 6 -- seconds per stash search
Config.BaseCooldown = 600 -- seconds fallback if a garage does not override cooldown
Config.Emotes = {
  lockpick = 'mechanic2', -- scully emote menu command name, e.g. /e mechanic2
  loot = 'search' -- scully emote menu command for rummaging
}

-- Mini-game settings
Config.Minigame = {
  lockpick = {
    enabled = true,
    mode = 'ox', -- 'ox' for built-in, 'export' for your own export, 'none' to skip
    ox = {
      type = 'sequence', -- 'sequence' (skillCheck) or 'circle' (skillCircle)
      stages = { 'easy', 'easy', 'medium', 'medium', 'hard' },
      inputs = { 'w', 'a', 's', 'd' },
      circle = { count = 3, speed = 0.75, size = 0.15 } -- used only when type = 'circle'
    },
    export = {
      resource = '', -- name of your resource providing a minigame export
      name = '', -- export name to call, must return boolean success
      args = {} -- optional args passed to the export
    }
  },
  loot = {
    enabled = true,
    mode = 'ox',
    ox = {
      type = 'sequence',
      stages = { 'easy', 'medium' },
      inputs = { 'w', 'a', 's', 'd' },
      circle = { count = 2, speed = 0.65, size = 0.18 }
    },
    export = {
      resource = '',
      name = '',
      args = {}
    }
  }
}

-- Dispatch settings; set system to: 'cd_dispatch', 'ps-dispatch', 'custom', or 'none'
Config.Dispatch = {
  system = 'cd_dispatch',
  customEvent = '', -- server-side event to trigger when system = 'custom'
  policeJobs = { 'police', 'sheriff' },
  code = '10-31',
  message = 'Garage burglary in progress',
  blip = { sprite = 357, color = 1, scale = 1.2 }
}

-- Interiors are editable. Replace with your own shell/MLO coordinates if desired.
Config.Interiors = {
  standard = {
    entry = vector4(1137.64, -3198.05, -39.67, 180.0),
    exit = vector4(1137.64, -3198.05, -39.67, 0.0),
    lootSpots = {
      vector4(1133.95, -3198.84, -39.67, 0.0),
      vector4(1141.22, -3197.33, -39.67, 180.0),
      vector4(1139.12, -3201.62, -39.67, 90.0)
    }
  },
  highend = {
    entry = vector4(1005.71, -3102.45, -39.0, 180.0),
    exit = vector4(1005.71, -3102.45, -39.0, 0.0),
    lootSpots = {
      vector4(1009.02, -3100.76, -39.0, 90.0),
      vector4(1002.92, -3100.12, -39.0, 270.0),
      vector4(1006.37, -3097.57, -39.0, 180.0),
      vector4(1003.43, -3097.56, -39.0, 180.0)
    }
  }
}

-- Garage doors in the world; adjust/add to match your map
Config.Garages = {
  {
    id = 'mirrorpark_1',
    label = 'Mirror Park Garage',
    coords = vector3(1146.29, -776.98, 57.61),
    heading = 85.0,
    type = 'standard',
    requiredPolice = 0,
    cooldown = 600
  },
  {
    id = 'little_seoul_1',
    label = 'Little Seoul Garage',
    coords = vector3(-712.42, -911.61, 19.22),
    heading = 0.0,
    type = 'standard',
    requiredPolice = 0,
    cooldown = 600
  },
  {
    id = 'richman_highend',
    label = 'Richman High-End Garage',
    coords = vector3(-796.95, 182.49, 72.84),
    heading = 180.0,
    type = 'highend',
    requiredPolice = 3,
    cooldown = 600
  }
}

-- Loot tables by garage type; each stash rolls across this list
Config.LootTables = {
  standard = {
    { item = 'money', min = 150, max = 350, chance = 60 },
    { item = 'water', min = 1, max = 3, chance = 80 },
    { item = 'sandwich', min = 1, max = 2, chance = 70 },
    { item = 'lockpick', min = 1, max = 1, chance = 20 }
  },
  highend = {
    { item = 'money', min = 450, max = 950, chance = 85 },
    { item = 'phone', min = 1, max = 1, chance = 25 },
    { item = 'rolex', min = 1, max = 2, chance = 30 },
    { item = 'bandage', min = 1, max = 2, chance = 50 },
    { item = 'lockpick', min = 1, max = 1, chance = 30 }
  }
}
