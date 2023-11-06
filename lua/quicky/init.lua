local Path = require "plenary.path"
local runner = require "quicky.runner"
local actions = {
    require "quicky.actions.makefile",
}

local M = {}
local config = {
    session_name = "quicky",
}

---@param opts table|nil
M.setup = function(opts)
    opts = opts or {}
    for k, v in pairs(opts) do
        config[k] = v
    end
end

M.workspace_actions = function()
    local ws_path = Path:new((vim.loop.cwd()))
    ws_path = ws_path:absolute()
    local ws_actions = {}
    for _, action in ipairs(actions) do
        action.add_workspace_actions(ws_path, ws_actions)
    end

    vim.ui.quicky(ws_actions, {
        prompt = "Workspace actions",
    }, function(item)
        local action = type(item) == "string" and item or item.action
        runner.run(action, ws_path, config.session_name)
    end)
end

return M
