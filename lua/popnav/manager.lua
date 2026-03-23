local M = {}

--- Check if the currently focused window is a floating window
---@return boolean
local function current_win_is_float()
  local win = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(win)
  return config.relative and config.relative ~= ""
end

---@class PopnavPopupDef
---@field name string           Display name (not required to be unique)
---@field open fun()
---@field close fun()
---@field is_open fun(): boolean
---@field icon? string

---@class PopnavPopupEntry
---@field id integer            Unique auto-assigned ID
---@field def PopnavPopupDef    The popup definition

--- Auto-increment counter for unique IDs
local next_id = 1

--- The ordered navigation list
---@type PopnavPopupEntry[]
M.list = {}

---@type integer|nil  Index into M.list
M.active_index = nil

-- ── List management ───────────────────────────────────────

--- Add a popup to the navigation list. Returns its unique ID.
---@param def PopnavPopupDef
---@return integer id
function M.add(def)
  local id = next_id
  next_id = next_id + 1
  local entry = { id = id, def = def }
  table.insert(M.list, entry)
  vim.notify("popnav: added '" .. def.name .. "' [" .. #M.list .. "]", vim.log.levels.INFO)
  return id
end

--- Remove a popup from the list by its position (1-based index)
---@param index integer
function M.remove_at(index)
  if index < 1 or index > #M.list then return end
  local entry = M.list[index]
  -- Close it if open
  if entry.def.is_open() then
    entry.def.close()
  end
  table.remove(M.list, index)
  -- Adjust active index
  if M.active_index then
    if M.active_index == index then
      M.active_index = nil
    elseif M.active_index > index then
      M.active_index = M.active_index - 1
    end
  end
  vim.notify("popnav: removed '" .. entry.def.name .. "'", vim.log.levels.INFO)
end

--- Remove a popup by its unique ID
---@param id integer
function M.remove_by_id(id)
  for i, entry in ipairs(M.list) do
    if entry.id == id then
      M.remove_at(i)
      return
    end
  end
end

--- Move a popup within the list (for reordering in the menu)
---@param from integer
---@param to integer
function M.move(from, to)
  if from < 1 or from > #M.list or to < 1 or to > #M.list then
    return
  end
  local entry = table.remove(M.list, from)
  table.insert(M.list, to, entry)
  if M.active_index == from then
    M.active_index = to
  elseif M.active_index then
    if from < M.active_index and to >= M.active_index then
      M.active_index = M.active_index - 1
    elseif from > M.active_index and to <= M.active_index then
      M.active_index = M.active_index + 1
    end
  end
end

--- Clear the entire navigation list
function M.clear()
  M.close_all()
  M.list = {}
  M.active_index = nil
end

-- ── Navigation ────────────────────────────────────────────

--- Close whichever popup is currently active
function M.close_active()
  for _, entry in ipairs(M.list) do
    if entry.def.is_open() then
      entry.def.close()
    end
  end
  M.active_index = nil
end

--- Open a popup and validate it produced a floating window
---@param entry PopnavPopupEntry
---@return boolean success
local function open_and_validate(entry)
  entry.def.open()
  -- Allow a brief moment for async openers, then check
  if not current_win_is_float() then
    vim.notify(
      "popnav: '" .. entry.def.name .. "' did not open a floating window — only floats are supported",
      vim.log.levels.WARN
    )
    -- Attempt to clean up whatever was opened
    pcall(entry.def.close)
    return false
  end
  return true
end

--- Open a popup by its position in the navigation list
---@param index integer
function M.select(index)
  if index < 1 or index > #M.list then return end

  local entry = M.list[index]

  if M.active_index == index and entry.def.is_open() then
    entry.def.close()
    M.active_index = nil
  else
    M.close_active()
    if open_and_validate(entry) then
      M.active_index = index
    end
  end
end

--- Navigate to the next popup in the list
function M.next()
  if #M.list == 0 then return end
  local current = M.active_index or 0
  local next_index = (current % #M.list) + 1
  M.close_active()
  if open_and_validate(M.list[next_index]) then
    M.active_index = next_index
  end
end

--- Navigate to the previous popup in the list
function M.prev()
  if #M.list == 0 then return end
  local current = M.active_index or 2
  local prev_index = ((current - 2) % #M.list) + 1
  M.close_active()
  if open_and_validate(M.list[prev_index]) then
    M.active_index = prev_index
  end
end

--- Close all popups in the list
function M.close_all()
  for _, entry in ipairs(M.list) do
    if entry.def.is_open() then
      entry.def.close()
    end
  end
  M.active_index = nil
end

--- Get the navigation list with status info
---@return { name: string, icon: string, is_open: boolean, index: integer, id: integer }[]
function M.status()
  local result = {}
  for i, entry in ipairs(M.list) do
    table.insert(result, {
      name = entry.def.name,
      icon = entry.def.icon or "",
      is_open = entry.def.is_open(),
      index = i,
      id = entry.id,
    })
  end
  return result
end

return M
