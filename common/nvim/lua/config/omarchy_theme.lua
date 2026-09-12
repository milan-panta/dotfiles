local M = {}

local current_theme_path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
local current_theme_name_path = vim.fn.expand("~/.local/state/omarchy/current/theme.name")
local last_applied_colorscheme = nil
local last_theme_signature = nil

local function remove_theme_yank_autocmd()
  -- Ashen installs a second yank highlighter that calls the deprecated
  -- vim.hl.on_yank(). Our config already provides this behavior via hl_op().
  pcall(vim.api.nvim_del_augroup_by_name, "ashen_highlight_yank")
end

local function get_current_theme_name()
  if vim.fn.filereadable(current_theme_name_path) == 1 then
    local lines = vim.fn.readfile(current_theme_name_path)
    if lines and #lines > 0 and lines[1] ~= "" then
      return vim.trim(lines[1])
    end
  end
  return nil
end

local function get_theme_file()
  if vim.fn.filereadable(current_theme_path) == 1 then
    return current_theme_path
  end

  local legacy_file = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
  if vim.fn.filereadable(legacy_file) == 1 then
    return legacy_file
  end
end

local function get_theme_signature(theme_file)
  local ok, lines = pcall(vim.fn.readfile, theme_file)
  if not ok then
    return nil
  end
  return table.concat(lines, "\n")
end

function M.apply_theme()
  local theme_file = get_theme_file()
  if not theme_file then
    return false
  end

  local ok, specs = pcall(dofile, theme_file)
  if not ok or type(specs) ~= "table" then
    return false
  end

  local colorscheme = nil
  local theme_plugin_name = nil
  local theme_plugin_opts = nil

  for _, spec in ipairs(specs) do
    if type(spec) == "table" then
      if spec[1] == "LazyVim/LazyVim" and spec.opts and spec.opts.colorscheme then
        colorscheme = spec.opts.colorscheme
        if spec.opts.background and colorscheme == "everforest" then
          vim.g.everforest_background = spec.opts.background
        end
      elseif spec[1] and spec[1] ~= "LazyVim/LazyVim" then
        theme_plugin_name = spec.name or spec[1]
        theme_plugin_opts = spec.opts
      end
    end
  end

  if not colorscheme then
    local theme_name = get_current_theme_name()
    if theme_name then
      colorscheme = theme_name:lower():gsub("%s+", "-")
    end
  end

  if not colorscheme then
    return false
  end

  -- Apply theme plugin options (such as aether palette or catppuccin flavour)
  if theme_plugin_name and theme_plugin_opts then
    local mod_name = theme_plugin_name:match("/([^/]+)$") or theme_plugin_name
    mod_name = mod_name:gsub("%.nvim$", "")
    pcall(function()
      local mod = require(mod_name)
      if mod and type(mod.setup) == "function" then
        mod.setup(theme_plugin_opts)
      end
    end)
  end

  -- Load via lazy loader if available
  pcall(function()
    local loader = require("lazy.core.loader")
    if loader then
      loader.colorscheme(colorscheme)
    end
  end)

  -- Clear existing highlights if switching live
  if last_applied_colorscheme and last_applied_colorscheme ~= colorscheme then
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then
      vim.cmd("syntax reset")
    end
  end

  local cs_ok, _ = pcall(vim.cmd.colorscheme, colorscheme)
  if cs_ok then
    remove_theme_yank_autocmd()
    last_applied_colorscheme = colorscheme
    last_theme_signature = get_theme_signature(theme_file)
    return true
  end

  return false
end

function M.setup()
  -- Apply active Omarchy theme on startup
  M.apply_theme()

  local group = vim.api.nvim_create_augroup("OmarchyThemeAutoReload", { clear = true })

  -- Check and re-apply on FocusGained
  vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
    group = group,
    callback = function()
      local theme_file = get_theme_file()
      if theme_file and get_theme_signature(theme_file) ~= last_theme_signature then
        M.apply_theme()
      end
    end,
  })

  -- Handle LazyReload if lazy detects theme file changes
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyReload",
    callback = function()
      M.apply_theme()
    end,
  })

  -- User command to manually reload or sync
  vim.api.nvim_create_user_command("OmarchyTheme", function()
    if M.apply_theme() then
      vim.notify("Omarchy theme applied: " .. (last_applied_colorscheme or "unknown"), vim.log.levels.INFO)
    else
      vim.notify("Failed to apply Omarchy theme", vim.log.levels.ERROR)
    end
  end, { desc = "Reload Omarchy theme in Neovim" })
end

return M
