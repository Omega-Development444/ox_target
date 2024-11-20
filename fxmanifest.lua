-- FX Information
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

-- Resource Information
name 'ox_target'
author 'Overextended'
version '1.13.1'
repository 'https://github.com/overextended/ox_target'
description ''

escrow_ignore {
	"OM.lua",
	"client/**",
	"server/**",
	"client/**/**"
}


-- Manifest
ui_page 'ui/dist/index.html'

shared_scripts {
	'@ox_lib/init.lua',
	'OM.lua'
}

client_scripts {
	'client/compat/statebags.lua',
	'client/main.lua',
}

server_scripts {
	'server/main.lua'
}

files {
	'ui/dist/**',
	'locales/*.json',
	'client/api.lua',
	'client/utils.lua',
	'client/state.lua',
	'client/debug.lua',
	'client/defaults.lua',
	'client/compat/qtarget.lua',
	'client/compat/qb-target.lua',
}

provide 'qtarget'
provide 'qb-target'

dependency 'ox_lib'

dependency '/assetpacks'