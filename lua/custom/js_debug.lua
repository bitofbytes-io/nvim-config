local M = {}

-- Launch Node directly: Mason's Windows .cmd shim is not a native executable
-- for libuv. Keep the entrypoint as one argv item, including paths with spaces.
function M.executable(mason_root, node)
  return {
    command = node ~= '' and node or 'node',
    args = {
      vim.fs.joinpath(mason_root, 'packages', 'js-debug-adapter', 'js-debug', 'src', 'dapDebugServer.js'),
      '${port}',
      '127.0.0.1',
    },
    detached = false,
  }
end

return M
