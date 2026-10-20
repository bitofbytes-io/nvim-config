-- Deterministic unit regression for delayed registry/installer callbacks.
-- The full startup test separately loads the real registry and installs tools.
local wait_for_tools = dofile 'scripts/wait-mason.lua'
local known, installed, installing, settled = false, false, false, false
local package = {
  is_installed = function()
    return installed
  end,
  is_installing = function()
    return installing
  end,
}
local registry = {
  has_package = function()
    return known
  end,
  get_package = function()
    return package
  end,
  get_all_packages = function()
    return { package }
  end,
}
-- Initially nothing is installing; the old idle-only check would return now.
vim.defer_fn(function()
  known, installing = true, true
end, 100)
vim.defer_fn(function()
  installed = true
end, 200)
vim.defer_fn(function()
  installing, settled = false, true
end, 300)
assert(wait_for_tools(registry, { 'js-debug-adapter' }, 2000), 'Delayed installation should complete before timeout')
assert(settled, 'Wait returned before the delayed installer finished')
installed = false
assert(not wait_for_tools(registry, { 'js-debug-adapter' }, 100), 'Missing adapter must time out even when no installer is active')
io.stdout:write 'Mason delayed-install and missing-package timeout regressions: passed\n'
