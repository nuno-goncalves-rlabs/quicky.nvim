return require("telescope").register_extension {
    setup = function(topts)
        topts.specific_opts = nil
        if #topts == 1 and topts[1] ~= nil then
            topts = topts[1]
        end

        local pickers = require "telescope.pickers"
        local finders = require "telescope.finders"
        local conf = require("telescope.config").values
        local actions = require "telescope.actions"
        local action_state = require "telescope.actions.state"
        local strings = require "plenary.strings"
        local entry_display = require "telescope.pickers.entry_display"

        vim.ui.quicky = function(ws_actions, opts, on_choice)
            opts = opts or {}
            local prompt = vim.F.if_nil(opts.prompt, "Select one of")
            if prompt:sub(-1, -1) == ":" then
                prompt = prompt:sub(1, -2)
            end
            opts.format_item = vim.F.if_nil(opts.format_item, function(e)
                return tostring(e)
            end)

            on_choice = vim.schedule_wrap(on_choice)
            local sopts = {
                make_indexed = function(items)
                    local indexed_items = {}
                    local widths = {
                        idx = 0,
                        action = 0,
                        context = 0,
                    }
                    for idx, item in ipairs(items) do
                        local context = item.context
                        local entry = {
                            idx = idx,
                            ["add"] = {
                                action = item.action
                                    :gsub("\r\n", "\\r\\n")
                                    :gsub("\n", "\\n"),
                                context = context,
                            },
                            text = item,
                        }
                        table.insert(indexed_items, entry)
                        widths.idx = math.max(
                            widths.idx,
                            strings.strdisplaywidth(entry.idx)
                        )
                        widths.action = math.max(
                            widths.action,
                            strings.strdisplaywidth(entry.add.action)
                        )
                        widths.context = math.max(
                            widths.context,
                            strings.strdisplaywidth(entry.add.context)
                        )
                    end
                    return indexed_items, widths
                end,
                make_displayer = function(widths)
                    return entry_display.create {
                        separator = " ",
                        items = {
                            { width = widths.idx + 1 }, -- +1 for ":" suffix
                            { width = widths.action },
                            { width = widths.context },
                        },
                    }
                end,
                make_display = function(displayer)
                    return function(e)
                        return displayer {
                            {
                                e.value.idx .. ":",
                                "TelescopePromptPrefix",
                            },
                            { e.value.add.action },
                            {
                                e.value.add.context,
                                "TelescopeResultsComment",
                            },
                        }
                    end
                end,
                make_ordinal = function(e)
                    return e.idx .. e.add["action"]
                end,
            }

            local indexed_items, widths = vim.F.if_nil(
                sopts.make_indexed,
                function(items_)
                    local indexed_items = {}
                    for idx, item in ipairs(items_) do
                        table.insert(indexed_items, { idx = idx, text = item })
                    end
                    return indexed_items
                end
            )(ws_actions)
            local displayer = vim.F.if_nil(sopts.make_displayer, function() end)(
                widths
            )
            local make_display = vim.F.if_nil(sopts.make_display, function(_)
                return function(e)
                    local x, _ = opts.format_item(e.value.text)
                    return x
                end
            end)(displayer)
            local make_ordinal = vim.F.if_nil(sopts.make_ordinal, function(e)
                return opts.format_item(e.text)
            end)
            pickers
                .new(topts, {
                    prompt_title = string.gsub(prompt, "\n", " "),
                    finder = finders.new_table {
                        results = indexed_items,
                        entry_maker = function(e)
                            return {
                                value = e,
                                display = make_display,
                                ordinal = make_ordinal(e),
                            }
                        end,
                    },
                    attach_mappings = function(prompt_bufnr)
                        actions.select_default:replace(function()
                            local selection = action_state.get_selected_entry()
                            actions.close(prompt_bufnr)
                            if selection == nil then
                                on_choice(action_state.get_current_line())
                            else
                                on_choice(
                                    selection.value.text,
                                    selection.value.idx
                                )
                            end
                        end)
                        return true
                    end,
                    sorter = conf.generic_sorter(topts),
                })
                :find()
        end
    end,
}
