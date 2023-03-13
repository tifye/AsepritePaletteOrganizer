MainDialog = Dialog()
MainDialog.bounds = Rectangle(250, MainDialog.bounds.y + 250, 250, 100)

PaletteGroupIds = {}

local ExtendDialogHeight = function(dialog, amount)
    local bounds = dialog.bounds
    MainDialog.bounds = Rectangle(bounds.x, bounds.y, bounds.width, bounds.height + amount)
end

local RemoveColorFromColorList = function (colorList, color)
    local colorListCopy = colorList
    local index = 0
    for i, curColor in ipairs(colorListCopy) do
        if curColor == color then
            index = i
            break
        end
    end

    table.remove(colorListCopy, index)
    return colorListCopy
end

-- ----------------------------- Palette Group Dialog ----------------------------- --
local AddPaletteGroupEditControls = function (dialog)
    local addColor = function (color)
        local colors = dialog.data.shades

        if #colors <= 0 then
            colors = { color = color }
        else
            table.insert(colors, #colors, color)
        end

        dialog:modify {
            id = "shades",
            colors = colors
        }
    end
    
    dialog
        :label { text = "Label" }
        :entry {
            id = "label",
            text = "Untitled"
        }
        :label { text = "Palette" }
        :label { text = "       " }
        :label { text = "(right click to remove color)" }
        :shades {
            id = "shades",
            mode = "sort",
            colors = { color = Color(0, 0, 0) },
            onclick = function (event)
                if event.button == MouseButton.RIGHT then
                    local colors = RemoveColorFromColorList(dialog.data.shades, event.color)
                    
                    dialog:modify {
                        id = "shades",
                        colors = colors
                    }
                end
            end
        }

    dialog
        :button {
            text="Add Foreground Color",
            onclick=function ()
                addColor(app.fgColor)
            end
        }
        :button {
            text="Add Background Color",
            onclick=function ()
                addColor(app.bgColor)
            end
        }
end

local CreateAddPaletteGroupDialog = function (onConfirm)
    local dialog = Dialog()
        :label { text = "Add Palette Group" }
        :separator {}

    AddPaletteGroupEditControls(dialog)

    dialog
        :separator {}
        :button {
            id = "confirm",
            text = "Add",
            onclick = function ()
                onConfirm(dialog.data)
                dialog:close()
            end

        }
        :button { id = "cancel", text = "Cancel" }

    return dialog
end

local ShowAddPaletteGroupDialog = function(onConfirm)
    local dialog = CreateAddPaletteGroupDialog(onConfirm)
    dialog:show { wait = false }
end

local OnAddGroup = function (dialog, data)
    local id = data.label
    local shadesId = id .. "Shades"

    MainDialog
    :label {
        id = id,
        text = data.label
    }
    :shades {
        id = shadesId,
        mode = "sort",
        colors = data.shades,
        onclick = function (event)
            if event.button == MouseButton.LEFT then
                app.fgColor = event.color
            elseif event.button == MouseButton.RIGHT then
                app.bgColor = event.color
            end
        end
    }

    table.insert(PaletteGroupIds, data.label)
    
    ExtendDialogHeight(dialog, 25)
end

local AddPaletteGroup = function(dialog)
    local onAddGroup = function (data)
        OnAddGroup(dialog, data)
    end

    ShowAddPaletteGroupDialog(onAddGroup)
end

local CreateEditPaletteGroupDialog = function (onConfirmEdit, groupsIdList)    
    local dialog = Dialog()

    dialog
        :label { text = "Edit Palette Group" }
        :combobox {
            id = "targetGroupId",
            option = 1,
            options = groupsIdList,
            onchange = function ()
                local targetGroupId = dialog.data.targetGroupId
                local colors = MainDialog.data[targetGroupId .. "Shades"]

                dialog
                    :modify {
                        id = "label",
                        text = MainDialog.data[targetGroupId]
                    }
                    :modify {
                        id = "shades",
                        colors = colors
                    }
            end
        }
        :separator {}

    AddPaletteGroupEditControls(dialog)

    dialog
        :separator {}
        :button {
            id = "confirm",
            text = "Apply Edit",
            onclick = function ()
                onConfirmEdit(dialog.data.targetGroupId, dialog.data)
            end
        }
        :button { id = "cancel", text = "Cancel" }

    return dialog
end

local ShowEditPaletteGroupDialog = function (onConfirm)
    local dialog = CreateEditPaletteGroupDialog(onConfirm, PaletteGroupIds)
    dialog:show { wait = false }
end

local OnEditGroup = function (dialog, targetGroupId, data)
    local targetShadesId = targetGroupId .. "Shades"

    dialog:modify {
        id = targetGroupId,
        text = data.label
    }

    dialog:modify {
        id = targetShadesId,
        colors = data.shades
    }
end

local EditPaletteGroups = function (dialog)
    for key, value in pairs(MainDialog.data) do
        print(key, value)
    end

    local onEditGroup = function (targetGroupId, data)
        OnEditGroup(dialog, targetGroupId, data)
    end

    ShowEditPaletteGroupDialog(onEditGroup)
end
-- ----------------------------- Palette Group Dialog ----------------------------- --

MainDialog
    :button {
        text="Add Group",
        onclick=function ()
            AddPaletteGroup(MainDialog)
        end
    }
    :button {
        text="Edit Groups",
        onclick=function ()
            EditPaletteGroups(MainDialog)
        end
    }
    :separator{}

MainDialog:show {
    wait=false
}


