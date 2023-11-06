local files_patterns = { makefile = true, Makefile = true }

---@param actions table
---@param path Path
---@param lines string[]
local function add_targets(actions, path, lines)
    local pos = #actions
    for _, line in ipairs(lines) do
        local target = line:match "^(%w+):.*$"
        if target then
            pos = pos + 1
            actions[pos] = {
                context = path.filename:match "[^/]*$",
                action = "make " .. target,
            }
        end
    end
end

local A = {}

---@param path Path
---@param buffer_lines table
---@param actions table
---@return table|nil
A.add_buffer_actions = function(path, buffer_lines, actions)
    if not files_patterns[path.filename] then
        return
    end

    add_targets(actions, path, buffer_lines)
end

---@param workspace_path Path
---@param actions table
---@return table|nil
A.add_workspace_actions = function(workspace_path, actions)
    local scanner = require "plenary.scandir"
    local files = scanner.scan_dir(workspace_path, {
        hidden = true,
        depth = 1,
        add_dirs = false,
        respect_gitignore = true,
        search_pattern = "[mM]akefile$",
    })

    if #files == 0 then
        return
    end

    local Path = require "plenary.path"
    for _, file in ipairs(files) do
        local path = Path:new(file)
        add_targets(actions, path, path:readlines())
    end
end

return A
