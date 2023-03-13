-- --------------------------- Main Dialog ---------------------------
local CreateMainDialog = function ()
    local dialog = Dialog {
        title = "Palette Organizer"
    }

    dialog.bounds = Rectangle(250, dialog.bounds.y + 250, 250, 100)

    dialog
    :button {
        text="Add Group",
        onclick=function ()
            -- AddPaletteGroup(MainDialog)
        end
    }
    :button {
        text="Edit Groups",
        onclick=function ()
            -- EditPaletteGroups(MainDialog)
        end
    }
    :separator {
        text = "Groups"
    }
    return dialog
end 
-- --------------------------- Main Dialog --------------------------
-- ------------------------------------------------------------------
-- --------------------------- Palette Group ------------------------
PaletteGroup = {}
PaletteGroup.__index = PaletteGroup

function PaletteGroup:new(id, label, colors)
    local self = setmetatable({}, PaletteGroup)
    self.id = id
    self.label = label
    self.colors = colors
    return self
end
-- --------------------------- Palette Group ------------------------

local MainDialog = CreateMainDialog()
MainDialog:show {
    wait=false
}