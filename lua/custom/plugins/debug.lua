return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = function(_, keys)
    local dap = require 'dap'
    local dapui = require 'dapui'
    return {
      -- Basic debugging keymaps, feel free to change to your liking!
      { '<F5>', dap.continue, desc = 'Debug: Start/Continue' },
      { '<F6>', dap.restart, desc = 'Debug: Restart' },
      { '<F4>', dap.terminate, desc = 'Debug: Terminate' },
      { '<F1>', dap.step_into, desc = 'Debug: Step Into' },
      { '<F2>', dap.step_over, desc = 'Debug: Step Over' },
      { '<F3>', dap.step_out, desc = 'Debug: Step Out' },
      { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
      {
        '<leader>B',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Set Breakpoint',
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      { '<F7>', dapui.toggle, desc = 'Debug: See last session result.' },
      unpack(keys),
    }
  end,
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Define custom signs for breakpoints
    vim.fn.sign_define('DapBreakpoint', {
      text = '🔴', -- Change this to any symbol you prefer
      texthl = 'LspDiagnosticsDefaultError', -- Highlight group for the sign
      linehl = '', -- Highlight the line with a different color, if desired
      numhl = '', -- Highlight the line number with a different color, if desired
    })

    vim.fn.sign_define('DapBreakpointCondition', {
      text = '🔵', -- Symbol for conditional breakpoints
      texthl = 'LspDiagnosticsDefaultWarning',
    })

    vim.fn.sign_define('DapBreakpointRejected', {
      text = '⚪', -- Symbol for rejected breakpoints
      texthl = 'LspDiagnosticsDefaultInformation',
    })

    -- Optional: You can set these as you configure your dap
    dap.listeners.after.event_initialized['custom_signs'] = function()
      vim.cmd 'sign place 9999 line=1 name=DapBreakpoint'
    end

    -- Set up the adapter for .NET (using netcoredbg)
    dap.adapters.coreclr = {
      type = 'executable',
      command = '/opt/netcoredbg/netcoredbg',
      args = { '--interpreter=vscode' },
    }

    -- Set up the configuration for .NET
    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'Launch - netcoredbg',
        request = 'launch',
        program = function()
          -- Get the first workspace folder from LSP (Omnisharp) or fallback to current dir
          local workspace_folders = vim.lsp.buf.list_workspace_folders()
          local root_path = workspace_folders[1] or vim.fn.getcwd()
          print('Detected project root path: ' .. root_path)

          -- Account for the nested project structure
          local project_name = vim.fn.fnamemodify(root_path, ':t')
          local dll_path = root_path .. '/' .. project_name .. '/bin/Debug/net8.0/' .. project_name .. '.dll'

          -- Check if the .dll file exists and build if it doesn’t
          if vim.fn.filereadable(dll_path) == 0 then
            print('Building project:\n' .. project_name)
            local build_output = vim.fn.system('dotnet build ' .. root_path)
            print('Build output:\n' .. build_output)
          end

          -- Confirm the .dll exists after the build attempt
          if vim.fn.filereadable(dll_path) == 1 then
            print 'Starting debugging session...'
            return dll_path
          else
            print('Error: .dll file still not found at ' .. dll_path)
            return vim.fn.input('Path to dll: ', dll_path, 'file')
          end
        end,
        cwd = function()
          -- Set the working directory to the folder containing the .dll
          local workspace_folders = vim.lsp.buf.list_workspace_folders()
          local root_path = workspace_folders[1] or vim.fn.getcwd()
          local project_name = vim.fn.fnamemodify(root_path, ':t')
          return root_path .. '/' .. project_name
        end,
        env = {
          DOTNET_ENVIRONMENT = 'Development',
        },
      },
      -- Debug azure function
      {
        type = 'coreclr',
        name = 'Launch Azure Function',
        request = 'launch',
        preLaunchTask = function()
          local function_name = vim.fn.input('Function Name to start: ', '', 'file')
          return 'func start --functions ' .. function_name
        end,
        program = function()
          -- Find the .dll file path similar to the previous configuration
          local workspace_folders = vim.lsp.buf.list_workspace_folders()
          local root_path = workspace_folders[1] or vim.fn.getcwd()
          local project_name = vim.fn.fnamemodify(root_path, ':t')
          return root_path .. '/' .. project_name .. '/bin/Debug/net8.0/' .. project_name .. '.dll'
        end,
        cwd = function()
          local workspace_folders = vim.lsp.buf.list_workspace_folders()
          return workspace_folders[1] or vim.fn.getcwd()
        end,
        env = {
          DOTNET_ENVIRONMENT = 'Development',
        },
        console = 'integratedTerminal',
      },
    }

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'netcoredbg',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup()

    -- Keymap to show variable info in a hover popup
    vim.keymap.set('n', '<leader>dh', function()
      dapui.eval() -- Opens the popup with information on the symbol under the cursor
    end, { desc = 'DAP Hover' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }
  end,
}
