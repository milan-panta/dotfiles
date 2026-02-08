return {
  "Civitasv/cmake-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  ft = { "c", "cpp", "cmake" },
  opts = {
    cmake_command = "cmake",
    ctest_command = "ctest",
    cmake_build_directory = "build/${variant:buildType}",
    cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
    cmake_soft_link_compile_commands = true,
    cmake_dap_configuration = {
      name = "cpp",
      type = "codelldb",
      request = "launch",
    },
  },
  keys = {
    { "<leader>Cc", "<cmd>CMakeGenerate<cr>", desc = "CMake: Configure" },
    { "<leader>Cb", "<cmd>CMakeBuild<cr>", desc = "CMake: Build" },
    { "<leader>Cr", "<cmd>CMakeRun<cr>", desc = "CMake: Run" },
    { "<leader>Cd", "<cmd>CMakeDebug<cr>", desc = "CMake: Debug" },
    { "<leader>Ct", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake: Select Target" },
    { "<leader>Cp", "<cmd>CMakeSelectBuildPreset<cr>", desc = "CMake: Select Preset" },
    { "<leader>CT", "<cmd>CMakeSelectBuildType<cr>", desc = "CMake: Select Build Type" },
    { "<leader>Cx", "<cmd>CMakeStop<cr>", desc = "CMake: Stop" },
  },
}
