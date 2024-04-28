-- settings.lua
local opt = vim.opt

opt.fileformat = 'unix'         -- Set file format to unix
opt.encoding = 'utf-8'          -- Set encoding to utf-8

opt.clipboard = "unnamedplus"   -- Use the system clipboard

opt.number = true               -- Show line numbers
opt.relativenumber = true       -- Show relative line numbers

opt.autoindent = true           -- Copy indent from current line when starting a new line
opt.expandtab = true            -- Use spaces instead of tabs
opt.shiftwidth = 4              -- Number of spaces to use for autoindent
opt.smartindent = true          -- Insert indents automatically
opt.smarttab = true             -- Use shiftwidth for tabstop
opt.tabstop = 4                 -- Number of spaces tabs count for
