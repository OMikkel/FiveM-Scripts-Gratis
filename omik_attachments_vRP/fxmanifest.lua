-- Lavet af: OMikkel#3217
-- Script: omik_attachments

fx_version "bodacious" -- fx_version 2020-02
game "gta5"

description "Et attachments script lavet af OMikkel#3217"

ui_page "html/index.html"

client_scripts {
    "config.lua",
    "lib/Tunnel.lua",
    "lib/Proxy.lua",
    "client.lua"
}

server_scripts {
    "config.lua",
    "@mysql-async/lib/MySQL.lua",
    "@vrp/lib/utils.lua",
    "server.lua"
}

files {
    "config.lua",
    "html/index.html",
    "html/index.css",
    "html/index.js"
}