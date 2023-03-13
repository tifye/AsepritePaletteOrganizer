-- --------------------------- Palette Group -------------------------
PaletteGroup = {}
PaletteGroup.__index = PaletteGroup

function PaletteGroup:new(id, label, colors)
    local self = setmetatable({}, PaletteGroup)
    self.id = id
    self.label = label
    self.colors = colors
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
-- --------------------------- Palette Group Collection --------------

-- --------------------------- Main Dialog ---------------------------
local CreateMainDialog = function (controller)
    local dialog = Dialog {
        title = "Palette Organizer"
    }

    dialog.bounds = Rectangle(250, dialog.bounds.y + 250, 250, 100)

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
local AttachPaletteGroupEditControls = function (dialog)
    
end
-- --------------------------- Helper Functions ---------------------

-- --------------------------- Controller ---------------------------
Controller = {}
Controller.__index = Controller

function Controller:new()
    local self = setmetatable({}, Controller)
    self.paletteGroups = PaletteGroupCollection:new()
    return self
end

function Controller:Start()
    local MainDialog = CreateMainDialog(self)
    MainDialog:show {
        wait=false
    }
end

function Controller:ShowAddPaletteGroupDialog()
    print("ShowAddPaletteGroupDialog")
end

function Controller:ShowEditPaletteGroupDialog()
    print("ShowEditPaletteGroupDialog")
end
-- --------------------------- Controller ---------------------------


local controller = Controller:new()
controller:Start()
