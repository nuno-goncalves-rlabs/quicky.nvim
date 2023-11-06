local Job = require "plenary.job"

local R = {}

---@param action string
---@param path Path
---@param session_name string
R.run = function(action, path, session_name)
    local curName
    Job:new({
        command = "tmux",
        args = { "display-message", "-p", "#W" },
        on_stdout = function(_, data)
            curName = data
        end,
    }):sync()
    local sess_exists
    Job:new({
        command = "tmux",
        args = { "new-session", "-ds", session_name, "-n", curName },
        on_exit = function(_, code, _)
            sess_exists = code ~= 0
        end,
    }):sync()
    local pane_id
    Job:new({
        command = "tmux",
        args = {
            "ls",
            "-f",
            "#{==:#{session_name}#{window_name},"
                .. session_name
                .. curName
                .. "}",
            "-F",
            "#{pane_id}",
        },
        on_stdout = function(_, data)
            pane_id = data
        end,
    }):sync()

    if not pane_id then
        Job:new({
            command = "tmux",
            args = {
                "new-window",
                "-n",
                curName,
                "-t",
                session_name,
                "-P",
                "-F",
                "#{pane_id}",
            },
            on_stdout = function(_, data)
                pane_id = data
            end,
        }):sync()
    elseif sess_exists then
        Job:new({
            command = "tmux",
            args = {
                "send-keys",
                "-t",
                session_name .. "." .. pane_id,
                "C-c",
            },
        }):sync()
    end

    local location = session_name .. "." .. pane_id
    Job:new({
        command = "tmux",
        args = { "send-keys", "-t", location, "cd " .. path, "C-m" },
    }):sync()
    Job:new({
        command = "tmux",
        args = { "send-keys", "-t", location, action, "C-m" },
    }):sync()
end

return R
