return {
  "3rd/image.nvim",
  config = function()
    -- Example for configuring Neovim to load user-installed installed Lua rocks:
    package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
    package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"
  end,
}
