fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'FD_garage_robbery'
author 'Fusion Development'
description 'ESX garage burglary using ox_inventory, ox_target and configurable dispatch'
version '1.0.0'

shared_scripts {
  '@es_extended/imports.lua',
  '@ox_lib/init.lua',
  'config.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  '@es_extended/imports.lua',
  'server/main.lua'
}

dependencies {
  'ox_lib',
  'ox_inventory',
  'ox_target',
  'es_extended'
}
