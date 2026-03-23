# popnav.nvim

Navigate between Neovim floating popups like [harpoon](https://github.com/ThePrimeagen/harpoon) navigates between files.

Add any floating window to a navigation list — terminals, cheatsheets, or anything else. Cycle through them with next/prev, jump by index, or pick from a menu. Multiple popups can share the same name (e.g. several terminals).

## Features

- **Any popup** — provide open/close/is_open callbacks; popnav doesn't care what it is
- **Add/remove dynamically** — curate your navigation list on the fly
- **Duplicates allowed** — add multiple terminals, multiple cheatsheets, whatever you need
- **Harpoon-style navigation** — next, prev, jump-to-index
- **Interactive menu** — select by number, reorder with J/K, delete with dd
- **One-at-a-time** — opening a popup auto-closes the current one

## Installation

### lazy.nvim

```lua
{
  "Jpifer13/popnav.nvim",
  version = "1.*",  -- pin to major version 1 (recommended)
  config = function()
    require("popnav").setup({
      popups = {
        {
          name = "Terminal",
          icon = "🖥",
          open = function() require("floating_terminal").toggle() end,
          close = function() require("floating_terminal").toggle() end,
          is_open = function()
            return _G.term_win and vim.api.nvim_win_is_valid(_G.term_win)
          end,
        },
        {
          name = "Cheatsheet",
          icon = "📋",
          open = function() require("cheatsheet").open() end,
          close = function() vim.cmd("close") end,
          is_open = function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "cheatsheet" then return true end
            end
            return false
          end,
        },
      },
    })
  end,
}
```

## Configuration

```lua
require("popnav").setup({
  -- Popups to add to the navigation list on startup
  popups = {
    {
      name = "Terminal",       -- display name (required, duplicates OK)
      icon = "🖥",             -- shown in menu (optional)
      open = function() end,   -- open the popup (required)
      close = function() end,  -- close/hide the popup (required)
      is_open = function()     -- return true if visible (required)
        return false
      end,
      destroy = function() end, -- fully tear down the popup (optional, see below)
    },
  },

  -- Menu highlight groups
  highlights = {
    active = { fg = "#a6e3a1", bold = true },
    inactive = { fg = "#585b70" },
    index = { fg = "#89b4fa", bold = true },
    name = { fg = "#cdd6f4" },
  },
})
```

### Callbacks

| Callback | Required | When it's called |
|---|---|---|
| `open` | Yes | When navigating to this popup (select, next, prev, menu Enter) |
| `close` | Yes | When navigating away — hides the popup but keeps any session alive |
| `is_open` | Yes | To check if the popup's floating window is currently visible |
| `destroy` | No | When the popup is **removed** from the list (menu `dd`, `remove_at()`, `clear()`) |

### The `destroy` callback

Some popups maintain a persistent session — a terminal keeps a shell process running, an AI panel keeps a connection open, etc. When these popups are navigated away from, `close` hides the window but the session stays alive so you can return to it later.

When a popup is **removed from the list** entirely, you probably want to kill the session too. That's what `destroy` is for. If provided, popnav calls `destroy` instead of `close` during removal. If not provided, it falls back to `close`.

Popnav can't provide a generic default for `destroy` because it doesn't track which window or buffer belongs to which popup — only your callbacks know that. So if your popup has a session that should be cleaned up on removal, you need to provide the `destroy` callback yourself.

**Example: terminal with destroy**

```lua
{
  name = "Terminal",
  open = function() require("my_terminal").open() end,
  close = function() require("my_terminal").close() end,      -- hides window, keeps shell
  destroy = function() require("my_terminal").destroy() end,   -- closes window + wipes buffer + kills shell
  is_open = function() return require("my_terminal").is_open() end,
}
```

**Example: cheatsheet without destroy**

A cheatsheet has no persistent session — the buffer is created fresh each time. No `destroy` needed; `close` is sufficient.

```lua
{
  name = "Cheatsheet",
  open = function() require("cheatsheet").open() end,
  close = function() vim.cmd("close") end,
  is_open = function() ... end,
  -- no destroy needed
}
```

## Keymaps

No keymaps are set by default. Suggested bindings:

```lua
local popnav = require("popnav")

vim.keymap.set("n", "<leader>pp", popnav.menu, { desc = "Popnav: menu" })
vim.keymap.set("n", "<leader>pn", popnav.next, { desc = "Popnav: next" })
vim.keymap.set("n", "<leader>pP", popnav.prev, { desc = "Popnav: prev" })
vim.keymap.set("n", "<leader>px", popnav.close_all, { desc = "Popnav: close all" })

-- Jump to popup by position
for i = 1, 9 do
  vim.keymap.set("n", "<leader>p" .. i, function()
    popnav.select(i)
  end, { desc = "Popnav: popup " .. i })
end

-- Add a new terminal popup dynamically
vim.keymap.set("n", "<leader>pt", function()
  popnav.add({
    name = "Terminal",
    icon = "🖥",
    open = function() require("floating_terminal").toggle() end,
    close = function() require("floating_terminal").toggle() end,
    is_open = function()
      return _G.term_win and vim.api.nvim_win_is_valid(_G.term_win)
    end,
  })
end, { desc = "Popnav: add terminal" })
```

## Commands

| Command | Description |
|---|---|
| `:Popnav` | Open the popup menu |
| `:Popnav menu` | Open the popup menu |
| `:Popnav next` | Switch to the next popup |
| `:Popnav prev` | Switch to the previous popup |
| `:Popnav close` | Close all popups |
| `:Popnav remove <index>` | Remove popup at position |
| `:Popnav clear` | Clear the entire list |
| `:Popnav <number>` | Jump to popup by position |

## Menu Controls

| Key | Action |
|---|---|
| `j/k` | Navigate up/down |
| `Enter` | Open selected popup |
| `1-9` | Jump to popup by number |
| `J/K` | Reorder (move entry down/up) |
| `dd` | Remove entry from list |
| `q` / `Esc` | Close menu |

## Lua API

```lua
local popnav = require("popnav")

-- List management
popnav.add(def)          -- Add a popup (returns unique ID)
popnav.remove_at(index)  -- Remove by position
popnav.remove_by_id(id)  -- Remove by unique ID
popnav.clear()           -- Clear the entire list

-- Navigation
popnav.select(index)     -- Toggle popup at position
popnav.next()            -- Cycle to next popup
popnav.prev()            -- Cycle to previous popup
popnav.close_all()       -- Close all popups

-- UI
popnav.menu()            -- Open the navigation menu
popnav.list()            -- Get list with status info
```

## How It Works

Each call to `popnav.add()` creates a new entry in the navigation list with a unique ID. Names are just display labels — you can have three entries all named "Terminal" if you want. The menu shows them by position, and you navigate by position (like harpoon slots).

Opening a popup auto-closes whichever one is currently active, so only one popup is visible at a time. Use `next()`/`prev()` to cycle, `select(n)` to jump, or the menu to pick visually.

## Versioning

popnav follows [semantic versioning](https://semver.org/). Releases are tagged as `v<major>.<minor>.<patch>`.

You can check the current version in Lua:

```lua
print(require("popnav").version)  -- e.g. "1.0.0"
```

To pin a version in lazy.nvim:

```lua
{ "Jpifer13/popnav.nvim", version = "1.*" }    -- latest v1.x.x (recommended)
{ "Jpifer13/popnav.nvim", version = "=1.0.0" } -- exact version
```
