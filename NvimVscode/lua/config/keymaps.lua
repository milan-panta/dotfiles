vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

-- better insert mode navigation
vim.keymap.set("i", "<C-b>", "<ESC>^i", { desc = "Beginning of line" })
vim.keymap.set("i", "<C-e>", "<End>", { desc = "End of line" })
vim.keymap.set({ "i", "s", "c" }, "<C-h>", "<Left>", { desc = "Move left" })
vim.keymap.set({ "i", "s", "c" }, "<C-l>", "<Right>", { desc = "Move right" })

-- maintain cursor position after joining
vim.keymap.set("n", "J", "mzJ`z")

-- paste without replacing clipboard
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

vim.keymap.set("o", "ir", "i[")
vim.keymap.set("o", "ar", "a[")
vim.keymap.set("o", "iq", 'i"')
vim.keymap.set("o", "aq", 'a"')

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>")

-- Shift y copies to macos clipboard
vim.keymap.set({ "n", "v" }, "Y", '"+y')

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>", { silent = true, desc = "Clear highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Define a function to send VSCode notifications
function VSCodeNotify(action)
  vim.fn["VSCodeNotify"](action)
end

vim.keymap.set("n", "<S-h>", function()
  vim.fn.feedkeys(":tabp\n")
end)
vim.keymap.set("n", "<S-l>", function()
  vim.fn.feedkeys(":tabn\n")
end)

-- Navigation between panes
vim.keymap.set(
  "n",
  "<C-k>",
  [[:lua VSCodeNotify('workbench.action.navigateUp')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<C-l>",
  [[:lua VSCodeNotify('workbench.action.navigateRight')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<C-j>",
  [[:lua VSCodeNotify('workbench.action.navigateDown')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<C-h>",
  [[:lua VSCodeNotify('workbench.action.navigateLeft')<CR>]],
  { noremap = true, silent = true }
)

-- Copilot keybinds
vim.keymap.set(
  { "n", "v" },
  "<Leader>ce",
  [[:lua VSCodeNotify('github.copilot.interactiveEditor.explain')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  { "n", "v" },
  "<Leader>cf",
  [[:lua VSCodeNotify('github.copilot.interactiveEditor.fix')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<Leader>cc",
  [[:lua VSCodeNotify('workbench.action.openQuickChat.copilot')<CR>]],
  { noremap = true, silent = true }
)

-- Pane management
vim.keymap.set(
  "n",
  "<C-q>",
  [[:lua VSCodeNotify('workbench.action.closeWindow')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<Leader>e",
  [[:lua VSCodeNotify('workbench.action.toggleSidebarVisibility')<CR>]],
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<C-w>\\",
  "[[:lua VSCodeNotify('workbench.action.splitEditor')<CR>]]",
  { noremap = true, silent = true }
)
vim.keymap.set(
  "n",
  "<C-w>-",
  "[[:lua VSCodeNotify('workbench.action.splitEditorDown')<CR>]]",
  { noremap = true, silent = true }
)

-- Formatting
vim.keymap.set(
  "n",
  "<Leader>lf",
  "[[:lua VSCodeNotify('editor.action.formatDocument')<CR>]]",
  { noremap = true, silent = true }
)
