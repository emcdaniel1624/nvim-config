return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = function()
    require('dashboard').setup {
      theme = 'hyper',
      config = {
        header = { -- Custom header section
          '███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
          '████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
          '██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║',
          '██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║',
          '██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║',
          '╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝',
        },
        week_header = {
          enabled = true,
        },
        project = {
          enable = false,
        },
      },
    }
  end,
  dependencies = { { 'nvim-tree/nvim-web-devicons' } },
}
