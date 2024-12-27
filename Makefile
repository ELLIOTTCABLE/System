makeFileDir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ALL_DHALL := $(shell fd --glob '*.dhall' "$(makeFileDir)" )
ALL_TOML := $(wildcard $(ALL_DHALL:%.dhall=%.toml))

DHALL_TO_TOML := $(makeFileDir)/Dotfiles/bin/dhall-to-toml-via-yq

print_all:
	@echo "Dhall sources: $(ALL_DHALL)"
	@echo "TOML targets: $(ALL_TOML)"

dhall: $(ALL_TOML)

$(ALL_TOML): %.toml: %.dhall
	$(DHALL_TO_TOML) $< > $@

wmill:
	cd $(makeFileDir)/Infrastructure/Windmill && \
	wmill sync pull --show-diffs
