RegisterNetEvent("esx:playerLoaded", function(data)
    ESX.PlayerData = data
end)

local UserDocuments = {}
local CurrentDocument = nil
local AllDocuments = nil
local Open = false

Citizen.CreateThread(function()
    AllDocuments = Config.Documents[Config.Locale]

    GetAllUserForms()
    SetNuiFocus(false, false)
end)

function OpenMainMenu()
    local elements = {
        {label = _U('public_documents'), value = "public"},
        {label = _U('saved_documents'), value = "saved"},
    }

    if AllDocuments[ESX.PlayerData.job.name] then
        table.insert(elements, 2, {label = _U('job_documents'), value = "job"})
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "main_menu", {
        title = _U("menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        if data.current.value == "public" then
            OpenNewPublicFormMenu()
        elseif data.current.value == "job" then
            OpenNewJobFormMenu()
        elseif data.current.value == "saved" then
            OpenMyDocumentsMenu()
        end
    end, function(date, menu)
        menu.close()
        Open = false
    end)
end

function CopyFormToPlayer(aPlayer)
    TriggerServerEvent('esx_documents:CopyToPlayer', aPlayer, CurrentDocument)
    CurrentDocument = nil;
end

function ShowToNearestPlayers(aDocument)
    local players = GetNearestPlayers()
    CurrentDocument = aDocument
    if #players <= 0 then
        TriggerEvent("noticeme:Error", {
            text = _U('no_player_found')
        })
        return
    end

    local elements = {}

    for i=1, #players, 1 do
        local player = players[i]
        table.insert(elements, {
            label = player.playerName,
            playerId = player.playerId
        })
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "nearest_menu", {
        title = _U("nearest_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        ShowDocument(data.current.playerId)
    end, function(date, menu)
        menu.close()
    end)
end

function CopyToNearestPlayers(aDocument)
    local players = GetNearestPlayers()
    CurrentDocument = aDocument
    if #players <= 0 then
        TriggerEvent("noticeme:Error", {
            text = _U('no_player_found')
        })
        return
    end

    local elements = {}

    for i=1, #players, 1 do
        local player = players[i]
        table.insert(elements, {
            label = player.playerName,
            playerId = player.playerId
        })
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "nearest_menu", {
        title = _U("nearest_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        CopyFormToPlayer(data.current.playerId)
    end, function(date, menu)
        menu.close()
    end)
end

function OpenNewPublicFormMenu()
    local elements = {}
    for i=1, #AllDocuments["public"], 1 do
        local document = AllDocuments["public"][i]
        table.insert(elements, {label = document.headerTitle, data = document})
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "public_menu", {
        title = _U("public_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        CreateNewForm(data.current.data)
    end, function(date, menu)
        OpenMainMenu()
    end)
end

function OpenNewJobFormMenu()
    local elements = {}
    for i=1, #AllDocuments[ESX.PlayerData.job.name], 1 do
        local document = AllDocuments[ESX.PlayerData.job.name][i]
        table.insert(elements, {label = document.headerTitle, data = document})
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "job_menu", {
        title = _U("job_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        CreateNewForm(data.current.data)
    end, function(date, menu)
        OpenMainMenu()
    end)
end

function OpenMyDocumentsMenu()
    local elements = {}
    for i=#UserDocuments, 1, -1 do
        local document = UserDocuments[i]

        table.insert(elements, {
            label = document.data.headerDateCreated .. " - " .. document.data.headerTitle,
            data = document
        })
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "saved_menu", {
        title = _U("saved_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        OpenFormPropertiesMenu(data.current.data)
    end, function(date, menu)
        OpenMainMenu()
    end)
end

function OpenFormPropertiesMenu(aDocument)
    local elements = {
        {label = _U('view_bt'), type = "view", data = aDocument.data},
        {label = _U('show_bt'), type = "show", data = aDocument.data},
        {label = _U('give_copy'), type = "copy", data = aDocument.data},
        {label = _U('delete_bt'), type = "delete", data = aDocument.data},
    }

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "form_menu", {
        title = _U("form_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        if data.current.type == "view" then
            ViewDocument(data.current.data)
        elseif data.current.type == "show" then
            ShowToNearestPlayers(data.current.data)
        elseif data.current.type == "copy" then
            CopyToNearestPlayers(data.current.data)
        elseif data.current.type == "delete" then
            DeleteDocument(data.current.data)
        end
    end, function(date, menu)
        OpenMyDocumentsMenu()
    end)
end

function OpenDeleteFormMenu(aDocument)
    local elements = {
        {label = _U('yes'), value = "yes", data = aDocument},
        {label = _U('no'), value = "no", data = aDocument},
    }

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open("default", GetCurrentResourceName(), "delete_menu", {
        title = _U("delete_menu_title"),
        align = "top-left",
        elements = elements
    }, function(data, menu)
        if data.current.value == "yes" then
            DeleteDocument(data.current.data)
        elseif data.current.value == "no" then
            OpenFormPropertiesMenu(data.current.data)
        end
    end, function(date, menu)
        menu.close()
    end)
end

function DeleteDocument(aDocument)
    local key_to_remove = nil

    ESX.TriggerServerCallback('esx_documents:deleteDocument', function (cb)
        if cb == true then
            --remove form_close
            for i=1, #UserDocuments, 1 do
                if UserDocuments[i].id == aDocument.id then
                    key_to_remove = i
                end
            end

            if key_to_remove ~= nil then
                table.remove(UserDocuments, key_to_remove)
            end
            OpenMyDocumentsMenu()
        end
    end, aDocument.id)
end

function CreateNewForm(aDocument)
    ESX.TriggerServerCallback('esx_documents:getPlayerDetails', function (player)
        if player ~= nil then
            SetNuiFocus(true, true)
            aDocument.headerFirstName = player.firstname
            aDocument.headerLastName = player.lastname
            aDocument.headerDateOfBirth = player.dateofbirth
            aDocument.headerJobLabel = ESX.PlayerData.job.label
            aDocument.headerJobGrade = ESX.PlayerData.job.grade_label
            aDocument.locale = Config.Locale

            SendNUIMessage({
                type = "createNewForm",
                data = aDocument
            })
        else
            print ("Received nil from newely created scale object.")
        end
    end)
end

function ShowDocument(aPlayer)
    TriggerServerEvent('esx_documents:ShowToPlayer', aPlayer, CurrentDocument)
    CurrentDocument = nil
end

RegisterNetEvent('esx_documents:viewDocument')
AddEventHandler('esx_documents:viewDocument', function( data )
    ViewDocument(data)
end)

function ViewDocument(aDocument)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "ShowDocument",
        data = aDocument
    })
end

RegisterNetEvent('esx_documents:copyForm')
AddEventHandler('esx_documents:copyForm', function( data )
    table.insert(UserDocuments, data)
end)

function CopyForm(aDocument)
end

function GetAllUserForms()
    ESX.TriggerServerCallback('esx_documents:getPlayerDocuments', function (cb_forms)
        if cb_forms ~= nil then
            UserDocuments = cb_forms
        else
            print ("Received nil from newely created scale object.")
        end
    end)

end

RegisterNUICallback('form_close', function()
    SetNuiFocus(false, false)
end)

RegisterNUICallback('form_submit', function(data, cb)
    ESX.TriggerServerCallback('esx_documents:submitDocument', function (cb_form)
        if cb_form ~= nil then
            table.insert(UserDocuments, cb_form)
            OpenFormPropertiesMenu(cb_form)
        else
            print ("Received nil from newely created scale object.")
        end
    end, data)

    SetNuiFocus(false, false)
end)

function GetNearestPlayers()
    local playerPed = PlayerPedId()
    local players, nearbyPlayer = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

    local players_clean = {}
    local found_players = false

    for i=1, #players, 1 do
        if players[i] ~= PlayerId() then
            found_players = true
            table.insert(players_clean, {playerName = GetPlayerName(players[i]), playerId = GetPlayerServerId(players[i])} )
        end
    end
    return players_clean
end

RegisterCommand("+showDocuments", function()
    if Open then
        ESX.UI.Menu.Close("default", GetCurrentResourceName(), "main_menu")
        ESX.UI.Menu.Close("default", GetCurrentResourceName(), "public_menu")
        ESX.UI.Menu.Close("default", GetCurrentResourceName(), "job_menu")
        ESX.UI.Menu.Close("default", GetCurrentResourceName(), "saved_menu")
        ESX.UI.Menu.Close("default", GetCurrentResourceName(), "nearest_menu")
        Open = false
    else
        OpenMainMenu()
        Open = true
    end
end)

RegisterCommand("-showDocuments", function()
end)

RegisterKeyMapping("+showDocuments", "Show legal documents", "keyboard", "K")