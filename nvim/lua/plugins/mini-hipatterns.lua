return {
  "nvim-mini/mini.hipatterns",
  event = { "BufReadPost", "BufNewFile" },
  opts = function()
    local hi = require("mini.hipatterns")
    return {
      highlighters = {
        fixme = { pattern = "%f[%w]()FIXME:()", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK:()", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO:()", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE:()", group = "MiniHipatternsNote" },
        hex_color = hi.gen_highlighter.hex_color({ priority = 2000 }),
        shorthand = {
          -- expand #RGB shorthand to #RRGGBB for color preview
          pattern = "()#%x%x%x()%f[^%x%w]",
          group = function(_, _, data)
            ---@type string
            local match = data.full_match
            local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
            local hex_color = "#" .. r .. r .. g .. g .. b .. b
            return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
          end,
          extmark_opts = { priority = 2000 },
        },
      },
    }
  end,
}
