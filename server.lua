ESX.RegisterServerCallback('esx_documents:submitDocument', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local db_form = nil;
    MySQL.Async.insert("INSERT INTO user_documents (owner, data) VALUES (@owner, @data)", {['@owner'] = xPlayer.identifier, ['@data'] = json.encode(data)}, function(id)
        if id ~= nil then
            MySQL.Async.fetchAll('SELECT * FROM user_documents where id = @id', {['@id']=id}, function (result)
                if(result[1] ~= nil) then
                    db_form = result[1]
                    db_form.data = json.decode(result[1].data)
                    cb(db_form)
                end
            end)
        else
            cb(db_form)
        end
    end)
end)

ESX.RegisterServerCallback('esx_documents:deleteDocument', function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.execute('DELETE FROM user_documents WHERE id = @id AND owner = @owner',{
        ['@id']  = id,
        ['@owner'] = xPlayer.identifier
    }, function(rowsChanged)
        if rowsChanged >= 1 then
            TriggerClientEvent('esx:showNotification', source, _U('document_deleted'))
            cb(true)
        else
            TriggerClientEvent('esx:showNotification', source, _U('document_delete_failed'))
            cb(false)
        end
    end)
end)

ESX.RegisterServerCallback('esx_documents:getPlayerDocuments', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local forms = {}
    if xPlayer ~= nil then
        MySQL.Async.fetchAll("SELECT * FROM user_documents WHERE owner = @owner", {['@owner'] = xPlayer.identifier}, function(result)
           if #result > 0 then
                for i=1, #result, 1 do
                    local tmp_result = result[i]
                    tmp_result.data = json.decode(result[i].data)

                    table.insert(forms, tmp_result)
                end
                cb(forms)
            end
        end)
    end
end)

ESX.RegisterServerCallback('esx_documents:getPlayerDetails', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local cb_data = nil

    MySQL.Async.fetchAll("SELECT firstname, lastname, dateofbirth FROM users WHERE identifier = @owner", {['@owner'] = xPlayer.identifier}, function(result)
        if result[1] ~= nil then
            cb_data = result[1]
            cb(cb_data)
        else
            cb(cb_data)
        end
    end)
end)

RegisterServerEvent('esx_documents:ShowToPlayer')
AddEventHandler('esx_documents:ShowToPlayer', function(targetID, aForm)
    TriggerClientEvent('esx_documents:viewDocument', targetID, aForm)
end)

RegisterServerEvent('esx_documents:CopyToPlayer')
AddEventHandler('esx_documents:CopyToPlayer', function(targetID, aForm)
    local _source   = source
    local targetId = ESX.GetPlayerFromId(targetID).source
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    MySQL.Async.insert("INSERT INTO user_documents (owner, data) VALUES (@owner, @data)", {['@owner'] = targetPlayer.identifier, ['@data'] = json.encode(aForm)}, function(id)
        if id ~= nil then
            MySQL.Async.fetchAll('SELECT * FROM user_documents where id = @id', {['@id']=id}, function (result)
                if(result[1] ~= nil) then
                    db_form = result[1]
                    db_form.data = json.decode(result[1].data)
                    TriggerClientEvent('esx_documents:copyForm', targetId, db_form)
                    TriggerClientEvent('esx:showNotification', targetId, _U('copy_from_player'))
                    TriggerClientEvent('esx:showNotification', _source, _U('from_copied_player'))
                else
                    TriggerClientEvent('esx:showNotification', _source, _U('could_not_copy_form_player'))
                end
            end)
        else
            TriggerClientEvent('esx:showNotification', _source, _U('could_not_copy_form_player'))
        end
    end)
end)