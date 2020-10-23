-- Script: omik_drugrun
-- Author: OMikkel#3217

fx_version "bodacious"
game "gta5"

description "OMikkel Gratis Drugrun script"

author "OMikkel#3217"

server_scripts {
    "config.lua",
    "@vrp/lib/utils.lua",
    "server.lua"
}

client_scripts {
    "config.lua",
    "lib/Tunnel.lua",
    "lib/Proxy.lua",
    "client.lua"
}

files {
    "config.lua"
}