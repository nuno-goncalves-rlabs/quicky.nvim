local makefile = require("quicky.actions.makefile")
local Path = require("plenary.path")

describe("makafile", function()
    it("current buffer not a makefile", function()
        local path = Path:new(("foo"))
        local actions = {}
        makefile.add_buffer_actions(path, {}, actions)
        assert.equals(0, #actions)
    end)

    it("multiple targets", function()
        local path = Path:new(("Makefile"))
        local lines = {
            ".PONHY: foo bar",
            "",
            "",
            "foo:",
            "   foo action",

            "bar:",
            "   bar action",

            "#some other stuff"
        }

        local actions = {}
        makefile.add_buffer_actions(path, lines, actions)
        assert.is_not_nil(actions)
        assert.equals(2, #actions)
        local action = actions[1]
        assert.is_not_nil(action)
        assert.equals("make foo", action.action)
        action = actions[2]
        assert.is_not_nil(action)
        assert.equals("make bar", action.action)
    end)

    it("workspace without makefile", function()
        local actions = {}
        makefile.add_workspace_actions(
            Path:new(("tests/quicky/actions/resources/makefile/without_makefile"))
            :absolute(), actions)
        assert.equals(0, #actions)
    end)

    it("workspace with makefile", function()
        local actions = {}
        makefile.add_workspace_actions(
            Path:new(("tests/quicky/actions/resources/makefile/with_makefile"))
            :absolute(), actions)
        assert.is_not_nil(actions)
        assert.equals(2, #actions)
    end)
end)
