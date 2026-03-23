local manager = require("popnav.manager")
local ui = require("popnav.ui")

local M = {}

local defaults = {
  highlights = {
    active = { fg = "#a6e3a1", bold = true },
    inactive = { fg = "#585b70" },
    index = { fg = "#89b4fa", bold = true },
    name = { fg = "#cdd6f4" },
  },
}

local function setup_highlights(opts)
  local hl = opts.highlights
  vim.api.nvim_set_hl(0, "PopnavActive", hl.active)
  vim.api.nvim_set_hl(0, "PopnavInactive", hl.inactive)
  vim.api.nvim_set_hl(0, "PopnavIndex", hl.index)
  vim.api.nvim_set_hl(0, "PopnavName", hl.name)
end

---@class PopnavOpts
---@field popups? PopnavPopupDef[]  Popups to add to the navigation list
---@field highlights? table

--- Setup popnav
---@param opts? PopnavOpts
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  setup_highlights(opts)

  -- Add popups to the navigation list
  if opts.popups then
    for _, popup in ipairs(opts.popups) do
      manager.add(popup)
    end
  end
end

--- Add a popup to the navigation list
---@param def PopnavPopupDef  Table with name, open, close, is_open (and optional icon)
---@return integer id  Unique ID for this entry
M.add = manager.add

--- Remove a popup by its position in the list
M.remove_at = manager.remove_at

--- Remove a popup by its unique ID
M.remove_by_id = manager.remove_by_id

--- Clear the entire list
M.clear = manager.clear

-- Navigation
M.select = manager.select
M.next = manager.next
M.prev = manager.prev
M.close_all = manager.close_all

-- UI
M.menu = ui.toggle

-- Info
M.list = manager.status

return M
