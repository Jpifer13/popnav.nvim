local manager = require("popnav.manager")

local M = {}

local menu_buf = nil
local menu_win = nil

local function is_menu_open()
  return menu_win and vim.api.nvim_win_is_valid(menu_win)
end

local function close_menu()
  if is_menu_open() then
    vim.api.nvim_win_close(menu_win, true)
  end
  menu_win = nil
  menu_buf = nil
end

local function refresh_menu()
  if not is_menu_open() then return end

  local items = manager.status()
  local lines = {}
  local ns = vim.api.nvim_create_namespace("popnav_menu")

  for _, item in ipairs(items) do
    local status = item.is_open and "●" or "○"
    local icon = item.icon ~= "" and (item.icon .. " ") or ""
    local line = string.format("  %s  %d  %s%s", status, item.index, icon, item.name)
    table.insert(lines, line)
  end

  if #lines == 0 then
    lines = { "  No popups in list" }
  end

  vim.bo[menu_buf].modifiable = true
  vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, lines)
  vim.bo[menu_buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(menu_buf, ns, 0, -1)
  for i, item in ipairs(items) do
    local status_hl = item.is_open and "PopnavActive" or "PopnavInactive"
    vim.api.nvim_buf_add_highlight(menu_buf, ns, status_hl, i - 1, 2, 3)
    vim.api.nvim_buf_add_highlight(menu_buf, ns, "PopnavIndex", i - 1, 5, 6)
    vim.api.nvim_buf_add_highlight(menu_buf, ns, "PopnavName", i - 1, 8, -1)
  end

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line) + 4)
  end
  width = math.max(width, 30)
  vim.api.nvim_win_set_width(menu_win, width)
  vim.api.nvim_win_set_height(menu_win, #lines)
end

function M.toggle()
  if is_menu_open() then
    close_menu()
    return
  end

  local items = manager.status()
  local lines = {}

  for _, item in ipairs(items) do
    local status = item.is_open and "●" or "○"
    local icon = item.icon ~= "" and (item.icon .. " ") or ""
    local line = string.format("  %s  %d  %s%s", status, item.index, icon, item.name)
    table.insert(lines, line)
  end

  if #lines == 0 then
    lines = { "  No popups in list" }
  end

  menu_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(menu_buf, 0, -1, false, lines)
  vim.bo[menu_buf].buftype = "nofile"
  vim.bo[menu_buf].bufhidden = "wipe"
  vim.bo[menu_buf].modifiable = false

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line) + 4)
  end
  width = math.max(width, 30)
  local height = #lines

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  menu_win = vim.api.nvim_open_win(menu_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Popups ",
    title_pos = "center",
  })

  vim.wo[menu_win].cursorline = true
  vim.wo[menu_win].number = false
  vim.wo[menu_win].relativenumber = false

  local ns = vim.api.nvim_create_namespace("popnav_menu")
  for i, item in ipairs(items) do
    local status_hl = item.is_open and "PopnavActive" or "PopnavInactive"
    vim.api.nvim_buf_add_highlight(menu_buf, ns, status_hl, i - 1, 2, 3)
    vim.api.nvim_buf_add_highlight(menu_buf, ns, "PopnavIndex", i - 1, 5, 6)
    vim.api.nvim_buf_add_highlight(menu_buf, ns, "PopnavName", i - 1, 8, -1)
  end

  local opts = { buffer = menu_buf, silent = true, nowait = true }

  vim.keymap.set("n", "q", close_menu, opts)
  vim.keymap.set("n", "<Esc>", close_menu, opts)

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(menu_win)[1]
    if line <= #manager.list then
      close_menu()
      manager.select(line)
    end
  end, opts)

  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      if i <= #manager.list then
        close_menu()
        manager.select(i)
      end
    end, opts)
  end

  vim.keymap.set("n", "dd", function()
    local line = vim.api.nvim_win_get_cursor(menu_win)[1]
    if line <= #manager.list then
      manager.remove_at(line)
      if #manager.list == 0 then
        close_menu()
      else
        refresh_menu()
        local new_line = math.min(line, #manager.list)
        vim.api.nvim_win_set_cursor(menu_win, { new_line, 0 })
      end
    end
  end, opts)

  vim.keymap.set("n", "K", function()
    local line = vim.api.nvim_win_get_cursor(menu_win)[1]
    if line > 1 and line <= #manager.list then
      manager.move(line, line - 1)
      refresh_menu()
      vim.api.nvim_win_set_cursor(menu_win, { line - 1, 0 })
    end
  end, opts)

  vim.keymap.set("n", "J", function()
    local line = vim.api.nvim_win_get_cursor(menu_win)[1]
    if line < #manager.list then
      manager.move(line, line + 1)
      refresh_menu()
      vim.api.nvim_win_set_cursor(menu_win, { line + 1, 0 })
    end
  end, opts)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = menu_buf,
    once = true,
    callback = close_menu,
  })
end

return M
