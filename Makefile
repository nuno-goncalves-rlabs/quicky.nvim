.PHONY: build

build:
	stylua lua/ --config-path=.stylua.toml
	luacheck lua/

test:
	nvim --headless -c "PlenaryBustedDirectory tests"

