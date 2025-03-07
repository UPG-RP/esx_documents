fx_version "cerulean"
game "gta5"

author "MineBill"
version "1.0.0"

ui_page "html/form.html"

files {
	"html/**.*",
}

shared_scripts {
	"@es_extended/imports.lua",
	"@es_extended/locale.lua",
	"config.lua",
	"locales/**.lua",
}

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"server.lua",
}

client_scripts {
	"client.lua",
}

dependencies {
	"es_extended"
}