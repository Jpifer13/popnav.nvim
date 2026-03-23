if vim.g.loaded_popnav then
  return
end
vim.g.loaded_popnav = true

vim.api.nvim_create_user_command("Popnav", function(args)
  local popnav = require("popnav")
  local subcmd = args.fargs[1]

  if subcmd == "menu" or subcmd == nil then
    popnav.menu()
  elseif subcmd == "next" then
    popnav.next()
  elseif subcmd == "prev" then
    popnav.prev()
  elseif subcmd == "close" then
    popnav.close_all()
  elseif subcmd == "clear" then
    popnav.clear()
  elseif subcmd == "remove" then
    local index = tonumber(args.fargs[2])
    if index then
      popnav.remove_at(index)
    else
      vim.notify("popnav: usage: :Popnav remove <index>", vim.log.levels.WARN)
    end
  elseif tonumber(subcmd) then
    popnav.select(tonumber(subcmd))
  else
    popnav.menu()
  end
end, {
  nargs = "*",
  complete = function(_, cmdline)
    local parts = vim.split(cmdline, "%s+")
    if #parts <= 2 then
      return { "menu", "next", "prev", "close", "remove", "clear" }
    end
    return {}
  end,
})
