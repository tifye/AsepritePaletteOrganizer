-- --------------------------- Profiles ------------------------------
local Profile = {}
Profile.__index = Profile

function Profile:new(name, paletteGroups)
    local self = setmetatable({}, Profile)
    self.name = name
    self.paletteGroups = paletteGroups
    return self
end

local ReadProfilesFile = function(relativeDirectory, filename)
    local file = io.open(relativeDirectory .. "\\" .. filename, "r")
    
    if file == nil then
        os.execute("mkdir \"" .. relativeDirectory .. "\"")
        file = io.open(relativeDirectory .. "\\" .. filename, "w")
        
        if file ~= nil then
            file:write("")
            file:close()
        end

        return "<Profiles></Profiles>"
    else
        local contents = file:read("*a")
        file:close()
        return contents
    end
end

local ParseColorXML = function (colorXML)
    local red = string.gmatch(colorXML, "red=\"(.-)\"")()
    local green = string.gmatch(colorXML, "green=\"(.-)\"")()
    local blue = string.gmatch(colorXML, "blue=\"(.-)\"")()
    local alpha = string.gmatch(colorXML, "alpha=\"(.-)\"")()

    return Color {
        red = tonumber(red),
        green =tonumber(green),
        blue = tonumber(blue),
        alpha = tonumber(alpha)
    }
end

local ParseColorsXML = function (colorsXML)
    local colorMatches = string.gmatch(colorsXML, "<Color (.-)></Color>")
    local colors = {}

    for match in colorMatches do
        local color = ParseColorXML(match)
        table.insert(colors, color)
    end

    return colors
end

local ParsePaletteGroupXML = function (groupXml)
    local groupId = string.gmatch(groupXml, "<Id>(.-)</Id>")()
    local groupLabel = string.gmatch(groupXml, "<Label>(.-)</Label>")()

    local colorsXML = string.gmatch(groupXml, "<Colors>(.-)</Colors>")()
    local groupColors = ParseColorsXML(colorsXML)

    return PaletteGroup:new(groupId, groupLabel, groupColors)
end

local PraseGroupsInProfile = function (profileContents)
    local groupMatches = string.gmatch(profileContents, "<Group>(.-)</Group>")
    local collection = PaletteGroupCollection:new()

    for match in groupMatches do
        local group = ParsePaletteGroupXML(match)
        collection:Add(group)
    end

    return collection
end

local ParseProfiles = function (fileContents)
    local profileMatches = string.gmatch(fileContents, "<Profile>(.-)</Profile>")
    local profiles = {}


    for match in profileMatches do
        local profileName = string.gmatch(match, "<Name>(.-)</Name>")()
        local groups = PraseGroupsInProfile(match)

        local profile = Profile:new(profileName, groups)
        profiles[#profiles] = profile
    end

    return profiles
end

local LoadProfiles = function ()
    local directory = "data/scripts/Palette Organizer"
    local filename = "profiles.xml"
    local fileContents = ReadProfilesFile(directory, filename)
    local profiles = ParseProfiles(fileContents)
    return profiles
end
-- --------------------------- Profiles ------------------------------

-- --------------------------- Palette Group -------------------------
PaletteGroup = {}
PaletteGroup.__index = PaletteGroup

function PaletteGroup:new(id, label, colors)
    local self = setmetatable({}, PaletteGroup)
    self.id = id
    self.label = label
    self.colors = colors

    self.labelId = id .. "_label"
    self.colorsId = id .. "_colors"
    return self
end
-- --------------------------- Palette Group -------------------------

-- --------------------------- Palette Group Collection --------------
PaletteGroupCollection = {}
PaletteGroupCollection.__index = PaletteGroupCollection

function PaletteGroupCollection:new()
    local self = setmetatable({}, PaletteGroupCollection)
    self.groups = {}
    return self
end

function PaletteGroupCollection:Add(paletteGroup)
    table.insert(self.groups, paletteGroup)
end

function PaletteGroupCollection:TryGet(id)
    local groudIndex = self:IndexOf(id)
    if groudIndex > -1 then
        return self.groups[groudIndex]
    end
    return nil
end

function PaletteGroupCollection:TryGetByLabel(label)
    for i, group in ipairs(self.groups) do
        if group.label == label then
            return group
        end
    end
    return nil
end

function PaletteGroupCollection:Remove(id)
    local groudIndex = self:IndexOf(id)
    if groudIndex > -1 then
        table.remove(self.groups, groudIndex)
    end
end

function PaletteGroupCollection:IndexOf(id)
    for i, group in ipairs(self.groups) do
        if group.id == id then
            return i
        end
    end
    return -1
end

function PaletteGroupCollection:Count()
    return #self.groups
end

function PaletteGroupCollection:GetLabels()
    local labels = {}
    for i, group in ipairs(self.groups) do
        table.insert(labels, group.label)
    end
    return labels
end

function PaletteGroupCollection:First()
    return self.groups[1]
end

function PaletteGroupCollection:Replace(id, paletteGroup)
    local groudIndex = self:IndexOf(id)
    if groudIndex > -1 then
        self.groups[groudIndex] = paletteGroup
    end
end
-- --------------------------- Palette Group Collection --------------

-- --------------------------- Main Dialog ---------------------------
local CreateMainDialog = function (controller)
    local dialog = Dialog {
        title = "Palette Organizer"
    }

    dialog.bounds = Rectangle(300, dialog.bounds.y + 250, 250, 100)

    dialog
    :button {
        text="Add Group",
        onclick=function ()
            controller:ShowAddPaletteGroupDialog()
        end
    }
    :button {
        text="Edit Groups",
        onclick=function ()
            controller:ShowEditPaletteGroupDialog()
        end
    }
    :separator {
        text = "Groups"
    }

    controller.mainDialog = dialog
    return dialog
end 
-- --------------------------- Main Dialog --------------------------

-- --------------------------- Helper Functions ---------------------
local ExtendDialogHeight = function(dialog, amount)
    local bounds = dialog.bounds
    dialog.bounds = Rectangle(bounds.x, bounds.y, bounds.width, bounds.height + amount)
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

local AddColorToColorList = function (colorList, color)
    local colors = colorList

    if #colors <= 0 then
        colors = { color = color }
    else
        table.insert(colors, #colors, color)
    end

    return colors
end

local AttachPaletteGroupEditControls = function (controller, dialog)
    dialog
    :label { text = "Label" }
    :entry {
        id = "label",
        text = "Untitled",
        onchange = function () 
            controller:EditLabelChanged(dialog, dialog.data.label)
        end
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
                dialog:modify { id = "shades", colors = colors }
            end
        end
    }

    dialog
    :button {
        text="Add Foreground Color",
        onclick=function ()
            local colors = AddColorToColorList(dialog.data.shades, app.fgColor)
            dialog:modify { id = "shades", colors = colors }
        end
    }
    :button {
        text="Add Background Color",
        onclick=function ()
            local colors = AddColorToColorList(dialog.data.shades, app.bgColor)
            dialog:modify { id = "shades", colors = colors }
        end
    }
end

local AttachPaletteGroupControls = function (dialog, paletteGroup)    
    dialog
    :label {
        id = paletteGroup.labelId,
        text = paletteGroup.label
    }
    :shades {
        id = paletteGroup.colorsId,
        mode = "sort",
        colors = paletteGroup.colors,
        onclick = function (event)
            if event.button == MouseButton.LEFT then
                app.fgColor = event.color
            elseif event.button == MouseButton.RIGHT then
                app.bgColor = event.color
            end
        end
    }
end
-- --------------------------- Helper Functions ---------------------

-- --------------------------- Add Palette Group Dialog -------------
local CreateAddPaletteGroupDialog = function (controller)
    local dialog = Dialog {
        title = "Add Palette Group",
        parent = controller.mainDialog
    }

    dialog.bounds = Rectangle(500, dialog.bounds.y + 250, 250, 150)

    AttachPaletteGroupEditControls(controller, dialog)

    dialog
    :separator {}
    :button {
        id="confirm",
        text="Add Group",
        enabled=false,
        onclick=function ()
            controller:AddGroupClicked()
            dialog:close()
        end
    }
    :button {
        id="cancel",
        text="Cancel",
        onclick=function ()
            dialog:close()
        end
    }

    return dialog
end
-- --------------------------- Add Palette Group Dialog -------------

-- --------------------------- Edit Palette Group Dialog ------------
local CreateEditPaletteGroupDialog = function (controller)
    local dialog = Dialog {
        title = "Edit Palette Group",
        parent = controller.mainDialog
    }

    dialog
    :combobox {
        id = "targetGroupLabel",
        option = 1,
        options = controller.paletteGroups:GetLabels(),
        onchange = function ()
            controller:EditTargetChanged(dialog.data.targetGroupLabel)
        end
    }

    AttachPaletteGroupEditControls(controller, dialog)

    dialog
    :separator {}
    :button {
        id = "confirm",
        text = "Apply Edit",
        enabled = true,
        onclick = function ()
            controller:ApplyEditClicked()
        end
    }
    :button { id = "cancel", text = "Cancel" }

    return dialog
end
-- --------------------------- Edit Palette Group Dialog ------------

-- --------------------------- Controller ---------------------------
Controller = {}
Controller.__index = Controller

function Controller:new()
    local self = setmetatable({}, Controller)

    local profiles = LoadProfiles()

    if profiles[0] == nil then
        self.paletteGroups = PaletteGroupCollection:new()
    else
        self.paletteGroups = profiles[0].paletteGroups
    end

    return self
end

function Controller:Start()
    local mainDialog = CreateMainDialog(self)
    self.mainDialog = mainDialog

    for i, paletteGroup in ipairs(self.paletteGroups.groups) do
        AttachPaletteGroupControls(mainDialog, paletteGroup)
        ExtendDialogHeight(mainDialog, 25)
    end

    mainDialog.bounds = Rectangle(250, mainDialog.bounds.y, 200, mainDialog.bounds.height)

    mainDialog:show {
        wait=false
    }
end

function Controller:AddGroupClicked()
    local data = self.addDialog.data
    local colors = data.shades
    local label = data.label
    local id = #self.paletteGroups.groups + 1
    local paletteGroup = PaletteGroup:new(id, label, colors)
    self.paletteGroups:Add(paletteGroup)

    local mainDialog = self.mainDialog
    AttachPaletteGroupControls(mainDialog, paletteGroup)
    ExtendDialogHeight(mainDialog, 25)
end

function Controller:ColorClicked(mouseButton, color, paletteGroupId)
    if mouseButton == MouseButton.LEFT then
        app.fgColor = color
    elseif mouseButton == MouseButton.RIGHT then
        app.bgColor = color
    end
end

function Controller:EditLabelChanged(dialog, label)
    local paletteGroup = self.paletteGroups:TryGetByLabel(label)
    if paletteGroup ~= nil then        
        dialog:modify { id = "confirm", enabled = false }
    else
        dialog:modify { id = "confirm", enabled = true }
    end
end

function Controller:EditTargetChanged(targetGroupLabel)
    if self.editDialog == nil then return end

    local paletteGroup = self.paletteGroups:TryGetByLabel(targetGroupLabel)
    if paletteGroup == nil then 
        print("Could not find palette group with label: " .. targetGroupLabel)
        return
    end
    
    local dialog = self.editDialog
    dialog
    :modify {
        id = "label",
        text = paletteGroup.label
    }
    :modify {
        id = "shades",
        colors = paletteGroup.colors
    }
end

function Controller:ApplyEditClicked()
    if self.editDialog == nil then return end
    
    local data = self.editDialog.data

    local paletteGroup = self.paletteGroups:TryGetByLabel(data.targetGroupLabel)
    if paletteGroup == nil then 
        print("Could not find palette group with label: " .. data.targetGroupLabel)
        return
    end

    paletteGroup.label = data.label
    paletteGroup.colors = data.shades
    self.paletteGroups:Replace(paletteGroup.id, paletteGroup)
    self:UpdatePaletteGroupUI(paletteGroup)
end

function Controller:UpdatePaletteGroupUI(paletteGroup)
    local mainDialog = self.mainDialog
    mainDialog:modify {
        id = paletteGroup.labelId,
        text = paletteGroup.label
    }
    mainDialog:modify {
        id = paletteGroup.colorsId,
        colors = paletteGroup.colors
    }
end

function Controller:ShowAddPaletteGroupDialog()
    self.addDialog = CreateAddPaletteGroupDialog(self)
    self.addDialog:show {
        wait=false
    }
end

function Controller:ShowEditPaletteGroupDialog()
    if self.paletteGroups:Count() <= 0 then 
        self:ShowAddPaletteGroupDialog()
        return
    end
    
    local defaultSelection = self.paletteGroups:First()

    self.editDialog = CreateEditPaletteGroupDialog(self)
    self:EditTargetChanged(defaultSelection.label)
    self.editDialog:show {
        wait=false
    }
end
-- --------------------------- Controller ---------------------------


local controller = Controller:new()
controller:Start()



