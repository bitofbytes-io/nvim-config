# Neovim configuration

Personal Neovim configuration based on
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).

## Requirements

- Neovim 0.12 or newer
- [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter) 0.26.1 or newer
- Git, Make, a C compiler, and [ripgrep](https://github.com/BurntSushi/ripgrep)
- `curl`, `tar`, and `unzip` for parser and Mason tool installation
- A [Nerd Font](https://www.nerdfonts.com/font-downloads)
- [LazyGit](https://github.com/jesseduffield/lazygit) for the LazyGit integration
- Go for language tooling and Mason-managed [Delve](https://github.com/go-delve/delve) debugging
- `gofmt` and [goimports](https://pkg.go.dev/golang.org/x/tools/cmd/goimports) for Go formatting
- Node.js and npm for the Mason-managed JavaScript debug adapter
- [Delta](https://github.com/dandavison/delta) for Telescope Undo diffs

## Notable plugins

The configuration includes kickstart.nvim's core plugins and enabled optional
modules (the lint module remains disabled), plus:

- [Telescope Undo](https://github.com/debugloop/telescope-undo.nvim)
- [LazyGit](https://github.com/kdheepak/lazygit.nvim)
- [Neotest](https://github.com/nvim-neotest/neotest) with Jest and Go adapters
- [Harpoon](https://github.com/ThePrimeagen/harpoon)
- [nvim-notify](https://github.com/rcarriga/nvim-notify)
- [Persistence](https://github.com/folke/persistence.nvim)
- [Trouble](https://github.com/folke/trouble.nvim)

Telescope tracks `master`. nvim-treesitter tracks `main`, installs parsers under
Neovim's data directory, and uses Neovim's built-in Treesitter highlighting API.

## Keybindings

`<leader>` is Space. Built-in mappings are discoverable with `<leader>sk`.

- `<leader>0` opens the Harpoon menu; `<leader>a` adds a file; `<leader>1` through
  `<leader>9` select Harpoon entries.
- `<leader>lg` opens LazyGit.
- `<leader>tr` runs tests; the other `<leader>t` mappings stop tests, open output,
  show the summary, debug, or toggle watch mode.
- `<leader>qs`, `<leader>ql`, `<leader>qS`, and `<leader>qd` restore, select, or
  stop Persistence sessions.
- `<leader>xx`, `<leader>xX`, `<leader>xq`, `<leader>cs`, and `<leader>cl` open
  Trouble diagnostics, quickfix, symbols, and LSP views.
- `<leader>s` contains Telescope search mappings; `<leader>u` opens Telescope Undo.
- `<F1>`, `<F2>`, `<F3>`, `<F5>`, `<F7>`, `<leader>b`, and `<leader>B` control debugging.

## Runtime state

lazy.nvim plugins, Treesitter parsers, Mason tools, caches, logs, undo history,
session data, and other runtime state live under Neovim's standard data, state,
and cache directories. `lazy-lock.json` is intentionally ignored, so plugin locks
and generated/runtime files must not be committed to this repository.

## Startup troubleshooting

If Neovim starts from a directory that has been deleted, the configuration
silently recovers to a valid `$HOME`, then falls back to Neovim's config
directory. A valid working directory is left unchanged. Startup stops with a
clear error if neither fallback directory is available.

## JavaScript debugging

Mason installs `js-debug-adapter` automatically (`js` is its mason-nvim-dap
adapter name). The configuration launches Mason's installed JavaScript entrypoint
with the native Node.js executable through nvim-dap's server support, including
on Windows where Mason's `.cmd` launcher cannot be spawned directly. Both the server
and client use `127.0.0.1` and an automatically allocated port, so no checkout
under a particular home directory is needed.
Use `:Mason` to inspect installation failures and `:MasonInstall js-debug-adapter`
to retry. Node.js must be available on PATH. The `pwa-node`, `pwa-chrome`,
`pwa-msedge`, `node-terminal`, and `pwa-extensionHost` adapters are registered;
provide the launch/attach configuration for your project through nvim-dap.

## Validation

Run `stylua --check .` and `python3 scripts/smoke.py --self-test` before submitting changes.
The smoke test needs Neovim, Git, Make, a C compiler, the Tree-sitter CLI, curl,
tar, unzip, ripgrep, Node.js/npm, Go, and Python 3.9+, plus network access to download
plugins/tools. It copies
the configuration into a temporary directory, isolates HOME and every XDG
location, installs actual plugins with `Lazy! sync`, and checks a second startup
for errors, warnings, and deprecations. It also starts the configured JavaScript
adapter, verifies a real DAP `initialize` response, and closes the session/server.
It waits
for delayed plugin and installer work with a bounded timeout. The artifact path
is printed so logs and the resolved plugin revisions can be inspected.
`NVIM_BIN` selects a different Neovim executable; `NVIM_SMOKE_ROOT` selects a new,
empty artifact directory. `--self-test` additionally verifies that injected early
and delayed warnings, a delayed Lua error, and a failed bootstrap are detected.
It also checks delayed Mason installation and missing-package timeout behavior.
CI runs these checks for pull requests and main pushes.

For bug reports, include relevant `:messages`, `:checkhealth`, and
`:checkhealth kickstart` output along with the Neovim version and config revision.
