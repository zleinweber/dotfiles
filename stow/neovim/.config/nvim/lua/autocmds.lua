-- autocmds.lua
local api = vim.api

-- Create an autogroup for managing filetype indent settings
api.nvim_create_augroup('FileTypeSettings', { clear = true })

-- Python settings
api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
    pattern = '*.py',
    group = 'FileTypeSettings',
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.textwidth = 79
    end
})

-- Bash / Shell settings
api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
    pattern = {'*.sh', '*.bash', '*.zsh', '*.fish'},
    group = 'FileTypeSettings',
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.textwidth = 120
    end
})

-- YAML settings
api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
    pattern = {'*.yaml', '*.yml'},
    group = 'FileTypeSettings',
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.textwidth = 120
    end
})

-- HTML, CSS, JS settings
api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
    pattern = {'*.html', '*.htm', '*.js', '*.css'},
    group = 'FileTypeSettings',
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.textwidth = 120
    end
})
