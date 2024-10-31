fx_version 'cerulean'
game 'gta5'

author 'GoodNetwork'
description "Fivem's most advanced garage"
version '1.0.0'

shared_script '@es_extended/imports.lua'
client_script 'client/client.lua'
shared_script 'config.lua'
files {
    'stream/*.ymap',
    'html/index.html',
    'html/styles.css',
    'html/sound/*.mp3',
    'html/img/*.png',
    'html/script.js'
}

ui_page 'html/index.html'

data_file 'DLC_ITYP_REQUEST' 'stream/*.ymap'