-- better naviation with line wrap on
vim.keymap.set("n", "j", "gj", { silent = true })
vim.keymap.set("n", "k", "gk", { silent = true })

-- qflist navigation
vim.keymap.set("n", "<Leader>q", "<cmd>copen<cr>", { desc = "Open qf list", silent = true })

-- kitty maps M to Cmmd inside tmux sessions
vim.keymap.set({ "n", "i" }, "<M-a>", "<ESC>ggVG")

-- paste without replacing clipboard
vim.keymap.set("x", "<Leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<Leader>d", [["_d]])

-- select occurrances of word
vim.keymap.set("n", "<Leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- maintain cursor position after joining
vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("o", "ir", "i[")
vim.keymap.set("o", "ar", "a[")
vim.keymap.set("o", "iq", 'i"')
vim.keymap.set("o", "aq", 'a"')

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>")

-- +y to copy to system clipboard
vim.keymap.set({ "n", "v" }, "Y", '"+y')

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- window management
vim.keymap.set("n", "<M-=>", ":resize -2<cr>", { silent = true, desc = "Increase height" })
vim.keymap.set("n", "<M-->", ":resize +2<cr>", { silent = true, desc = "Decrease height" })
vim.keymap.set("n", "<M-.>", ":vertical resize +2<cr>", { silent = true, desc = "Increase width" })
vim.keymap.set("n", "<M-,>", ":vertical resize -2<cr>", { silent = true, desc = "Decrease width" })

-- Consistent with tmux
vim.keymap.set("n", "<C-w>-", "<C-w>s", { desc = "Create horizontal split" })
vim.keymap.set("n", "<C-w>\\", "<C-w>v", { desc = "Create vertical split" })
vim.keymap.set("n", "<C-w>z", "<C-w>_<C-w>|", { desc = "Max out split" })

-- run file
local function RunFile(dir, args)
  args = args or ""
  vim.cmd("w")
  local file = vim.fn.expand("%")
  local file_no_ext = vim.fn.expand("%:r")
  local filetype = vim.bo.filetype
  local cmd = ""

  if filetype == "c" then
    cmd = string.format("gcc -Wall -g -std=gnu99 '%s' -o '%s' && '%s' %s", file, file_no_ext, file_no_ext, args)
  elseif filetype == "cpp" then
    cmd = string.format("g++-15 -g -std=c++23 -Wall '%s' -o '%s' && '%s' %s", file, file_no_ext, file_no_ext, args)
  elseif filetype == "python" then
    cmd = string.format("python3 -u '%s' %s", file, args)
  elseif filetype == "rust" then
    if args ~= "" then
      cmd = "cargo run -- " .. args
    else
      cmd = "cargo run"
    end
  elseif filetype == "javascript" then
    cmd = string.format("node '%s' %s", file, args)
  else
    vim.notify("Filetype " .. filetype .. " is not supported", vim.log.levels.WARN)
    return
  end

  vim.cmd(dir)
  vim.cmd("term " .. cmd .. "; " .. (vim.env.SHELL or "zsh"))
  vim.cmd("startinsert")
end

-- code running
vim.keymap.set("n", "<Leader>r\\", function()
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input then
      RunFile("vsplit", input)
    end
  end)
end, { silent = true, desc = "Run vertically" })
vim.keymap.set("n", "<Leader>r-", function()
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input then
      RunFile("split", input)
    end
  end)
end, { silent = true, desc = "Run horizontally" })

-- markdown preview runner
vim.keymap.set("n", "<Leader>rm", "<Cmd>MarkdownPreviewToggle<cr>")
