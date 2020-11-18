-------------------------------------------------------------------------
------- Created by T1GER#9080  - Converted to vRP by OMikkel#3217 -------
-------------------------------------------------------------------------

fx_version "bodacious"
game "gta5"

description 'T1GER New Drugs - Converted to vRP by OMikkel#"3217'

author 'T1GER#9080'

ui_page "html/index.html"

client_scripts {
    "lib/Tunnel.lua",
    "lib/Proxy.lua",
    "config.lua",
    "client/client.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
    "@mysql-async/lib/MySQL.lua",
    "config.lua",
    "server/server.lua"
}

files {
    "html/index.js",
    "html/index.css",
    "html/index.html"
}