-- settings.lua
local opt = vim.opt

-- Example settings
opt.number = true            -- Show line numbers
opt.relativenumber = true    -- Show relative line numbers
opt.clipboard = "unnamedplus" -- Use the system clipboard
opt.tabstop = 4              -- Number of spaces tabs count for
opt.shiftwidth = 4           -- Number of spaces to use for autoindent
opt.expandtab = true         -- Use spaces instead of tabs
opt.smartindent = true       -- Insert indents automatically
opt.autoindent = true        -- Copy indent from current line when starting a new line
