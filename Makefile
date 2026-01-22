.DEFAULT_GOAL := build

ARTIFACT = committer

ifeq ($(OS),Windows_NT)
	ARTIFACT = committer.exe
endif

NC = nimble
NFLAGS = --verbose -o:$(ARTIFACT)


clean:
	@rm -rf $(ARTIFACT)

build: clean
	@printf "\nCOMMITTER BUILD\n"
	@printf "\n>>> parameters\n"
	@printf "* NC: %s (%s)\n" "$(NC)" "$(shell which $(NC))"
	@printf "* NFLAGS: %s\n" "$(strip $(NFLAGS))"
	@printf "* PATH:\n" "$(PATH)"
	@echo "$(PATH)" | tr ':' '\n' | xargs -n 1 printf "   - %s\n"
	@printf "\n"
	@printf "\n>>> compile\n"
	$(NC) build $(NFLAGS)
	@printf "\n* binary size: "
	@du -h $(ARTIFACT) | cut -f -1
	@printf "\nDONE\n"

release: NFLAGS += -d:release
release: build
	@strip $(ARTIFACT)
