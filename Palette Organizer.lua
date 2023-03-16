-- --------------------------- Profile -------------------------------
local Profile = {}
Profile.__index = Profile

function Profile:new(id, name, paletteGroups)
    local self = setmetatable({}, Profile)
    self.id = id
    self.name = name
    self.paletteGroups = paletteGroups
    return self
end
-- --------------------------- Profile -------------------------------

-- --------------------------- ProfileCollection ---------------------
ProfileCollection = {}
ProfileCollection.__index = ProfileCollection

function ProfileCollection:new()
    local self = setmetatable({}, ProfileCollection)
    self.profiles = {}
    return self
end

function ProfileCollection:Add(profile)
    table.insert(self.profiles, profile)
end

function ProfileCollection:TryGetByName(name)
    local profileIndex = self:IndexOf(name)
    if profileIndex > -1 then
        return self.profiles[profileIndex]
    end
    return nil
end

function ProfileCollection:TryGet(id)
    local profileIndex = self:IndexOf(id)
    if profileIndex > -1 then
        return self.profiles[profileIndex]
    end
    return nil
end

function ProfileCollection:First()
    return self.profiles[1]
end

function ProfileCollection:Remove(name)
    local profileIndex = self:IndexOf(name)
    if profileIndex > -1 then
        table.remove(self.profiles, profileIndex)
    end
end

function ProfileCollection:IndexOf(query)
    for i, profile in ipairs(self.profiles) do
        if profile.name == query or profile.id == query then
            return i
        end
    end
    return -1
end

function ProfileCollection:Replace(index, profile) 
    self.profiles[index] = profile
end

function ProfileCollection:At(index)
    return self.profiles[index]
end

function ProfileCollection:Count()
    return #self.profiles
end

function ProfileCollection:GetNames()
    local names = {}
    for i, profile in ipairs(self.profiles) do
        table.insert(names, profile.name)
    end
    return names
end
-- --------------------------- ProfileCollection ---------------------

-- --------------------------- Profiles ------------------------------
-- I know this looks like a mess. If i ever need to change the structure of how
-- profiles are saved then i will write a generic xml parser. For now this is fine.

-- --------------------------- Load Profiles -------------------------
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
    local profiles = ProfileCollection:new()

    for match in profileMatches do
        local profileId = string.gmatch(match, "<Id>(.-)</Id>")()
        local profileName = string.gmatch(match, "<Name>(.-)</Name>")()
        local groups = PraseGroupsInProfile(match)

        local profile = Profile:new(profileId, profileName, groups)
        profiles:Add(profile)
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
-- --------------------------- Load Profiles -------------------------
-- --------------------------- Save Profiles -------------------------
local SaveXMLToFile = function (xml, relativeDirectory, filename)
    local path = relativeDirectory .. "\\" .. filename
    local file = io.open(path, "w")
    
    if file == nil then
        print("An error occured while saving the file: " .. path)
        return
    end

    file:write(xml)
    file:close()
end

local SaveProfilesXMLToFile = function (profilesXml)
    local directory = "data/scripts/Palette Organizer"
    local filename = "profiles.xml"
    SaveXMLToFile(profilesXml, directory, filename)
end

local ColorToXML = function (color)
    return "<Color red=\"" .. color.red .. "\" green=\"" .. color.green .. "\" blue=\"" .. color.blue .. "\" alpha=\"" .. color.alpha .. "\"></Color>"
end

local PaletteGroupToXML = function (paletteGroup)
    local xml = "<Group>"
    xml = xml .. "<Id>" .. paletteGroup.id .. "</Id>"
    xml = xml .. "<Label>" .. paletteGroup.label .. "</Label>"
    xml = xml .. "<Colors>"

    for i, color in ipairs(paletteGroup.colors) do
        xml = xml .. ColorToXML(color)
    end

    xml = xml .. "</Colors>"
    xml = xml .. "</Group>"
    return xml
end

local PaletteGroupCollectionToXML = function (paletteGroupCollection)
    local xml = "<Groups>"
    for i, group in ipairs(paletteGroupCollection.groups) do
        xml = xml .. PaletteGroupToXML(group)
    end
    xml = xml .. "</Groups>"
    return xml
end

local ProfileToXML = function (profile)
    local xml = "<Profile>"
    xml = xml .. "<Id>" .. profile.id .. "</Id>"
    xml = xml .. "<Name>" .. profile.name .. "</Name>"
    xml = xml .. "<Groups>" .. PaletteGroupCollectionToXML(profile.paletteGroups) .. "</Groups>"
    xml = xml .. "</Profile>"
    return xml
end

local ProfilesCollectionToXML = function (profiles)
    local xml = "<Profiles>"
    for i, profile in ipairs(profiles.profiles) do
        xml = xml .. ProfileToXML(profile)
    end
    xml = xml .. "</Profiles>"
    return xml
end

local SaveProfiles = function (profiles)
    local xml = ProfilesCollectionToXML(profiles)
    SaveProfilesXMLToFile(xml)
end
-- --------------------------- Save Profiles -------------------------
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
        text = "Profiles",
        focus = false,
        onclick=function ()
            controller:ShowProfileManagerDialog()
        end
    }
    :button {
        text="Add Group",
        onclick=function ()
            controller:ShowAddPaletteGroupDialog()
        end
    }
    :button {
        text="Edit Group",
        onclick=function ()
            controller:ShowEditPaletteGroupDialog()
        end
    }
    :separator {
        id = "profileName",
        text = controller.activeProfile.name
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

local ConfirmDialog = function (title, prompt)
    local dialog = Dialog { title = title }
    dialog
    :label { text = prompt }
    :button {
        id="confirm",
        text="OK",
        onclick=function ()
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

    dialog:show { wait = true }

    return dialog
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
        id = "delete",
        text = "Delete Group",
        onclick = function ()
            controller:DeleteGroupClicked()
        end
    }
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

-- --------------------------- Profile Manager Dialog ---------------
local CreateProfilesManagerDialog = function (controller)
    local dialog = Dialog("Profile Manager")

    local profileNames = controller.profiles:GetNames()

    dialog
    :button {
        text = "New Profile",
        onclick = function ()
            controller:NewProfile()
        end
    }
    :combobox {
        id = "targetProfile",
        option = controller.activeProfile.name,
        options = profileNames,
        onchange = function ()
            dialog:modify { id = "editProfileName", text = dialog.data.targetProfile }
        end
    }
    :label {
        text = "Edit Profile Name"
    }
    :entry {
        id = "editProfileName",
        text = dialog.data.targetProfile,
        onchange = function ()
        end
    }

    :separator {}
    :button {
        text = "Select Profile",
        onclick = function ()
            controller:SelectProfileClicked()
        end
    }
    :button {
        text = "Apply Edit",
        onclick = function ()
            controller:ApplyProfileEditClicked()
        end
    }
    :button {
        text = "Close"
    }
    

    return dialog
end
-- --------------------------- Profile Manager Dialog ---------------

-- --------------------------- Controller ---------------------------
Controller = {}
Controller.__index = Controller

function Controller:new()
    local self = setmetatable({}, Controller)

    local profiles = LoadProfiles()
    self.profiles = profiles

    local activeProfile = profiles:First()

    if activeProfile == nil then
        local paletteGroups = PaletteGroupCollection:new()
        self.activeProfile = Profile:new(1, "Untitled Profile", paletteGroups)
        self.paletteGroups = paletteGroups

        profiles:Add(self.activeProfile)
    else
        self.activeProfile = activeProfile
        self.paletteGroups = activeProfile.paletteGroups
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
    ExtendDialogHeight(mainDialog, 40)

    self:SaveProfiles(self.profiles)
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

    self:SaveProfiles(self.profiles)
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

function Controller:ShowProfileManagerDialog()    
    self.profileManagerDialog = CreateProfilesManagerDialog(self)
    self.profileManagerDialog:show {
        wait=true
    }
end

function Controller:ApplyProfileEditClicked()
    local data = self.profileManagerDialog.data

    local profile = self.profiles:TryGetByName(data.targetProfile)
    if profile == nil then
        print("Could not find profile with name: " .. data.targetProfile)
        return
    end

    profile.name = data.editProfileName

    self.profileManagerDialog:modify {
        id = "targetProfile",
        option = data.editProfileName,
        options = self.profiles:GetNames()
    }
    
    if self.activeProfile.id == profile.id then
        self:SetMainDialogProfileName(data.editProfileName)
    end

    self:SaveProfiles(self.profiles)
end

function Controller:SetMainDialogProfileName(profileName)
    self.mainDialog:modify {
        id = "profileName",
        text = profileName
    }
end

function Controller:SetActiveProfile(profile)
    self.activeProfile = profile
    self.paletteGroups = profile.paletteGroups
    self:SetMainDialogProfileName(profile.name)    
end

function Controller:SwitchProfile(profile)
    self:SetActiveProfile(profile)
    self:Refresh()
end

function Controller:Refresh()
    self:CloseDialogs()
    self:Start()
end

function Controller:CloseDialogs()
    self.mainDialog:close()

    if self.editDialog ~= nil then
        self.editDialog:close()
    end

    if self.addDialog ~= nil then
        self.addDialog:close()
    end

    if self.profileManagerDialog ~= nil then
        self.profileManagerDialog:close()
    end
end

function Controller:SelectProfileClicked()
    local selectedProfileName = self.profileManagerDialog.data.targetProfile
    local profile = self.profiles:TryGetByName(selectedProfileName)

    if profile == nil then
        print("Could not find profile with name: " .. selectedProfileName)
        return
    end

    self:SwitchProfile(profile)
end

function Controller:SaveProfiles(profiles)
    SaveProfiles(profiles)
end

function Controller:NewProfile()
    local profile = Profile:new(self.profiles:Count()+1, "Untitled Profile", PaletteGroupCollection:new())
    self.profiles:Add(profile)
    self:SwitchProfile(profile)
    self:ShowProfileManagerDialog()
    self:SaveProfiles(self.profiles)
end

function Controller:DeleteGroupClicked()
    local selectedGroupLabel = self.editDialog.data.targetGroupLabel
    local paletteGroup = self.paletteGroups:TryGetByLabel(selectedGroupLabel)

    if paletteGroup == nil then
        print("Could not find palette group with label: " .. selectedGroupLabel)
        return
    end

    local confirmDialog = ConfirmDialog("Delete Palette Group", "Are you sure you want to delete palette group: " .. paletteGroup.label .. "?")
    if confirmDialog.data.confirm then
        self.paletteGroups:Remove(paletteGroup.id)
        self:Refresh()
        self:SaveProfiles(self.profiles)
    end
end
-- --------------------------- Controller ---------------------------

os.execute("mkdir \"" .. "data\\script\\Palette Organizer" .. "\"")
local controller = Controller:new()
controller:Start()



