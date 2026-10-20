-- An empty active-install list is not sufficient: registry refresh and install
-- callbacks can still be queued. Require the requested packages to exist first.
return function(registry, required, timeout)
  return vim.wait(timeout, function()
    for _, name in ipairs(required) do
      if not registry.has_package(name) or not registry.get_package(name):is_installed() then
        return false
      end
    end
    for _, package in ipairs(registry.get_all_packages()) do
      if package:is_installing() then
        return false
      end
    end
    return true
  end, 50)
end
