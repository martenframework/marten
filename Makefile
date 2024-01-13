init:
	@printf "\n\n${YELLOW}---------------- Initialization ---${RESET} ${GREEN}Crystal dependencies${RESET}\n\n"

	shards install

	@printf "\n\n${YELLOW}---------------- Initialization ---${RESET} ${GREEN}Node.js dependencies${RESET}\n\n"

	cd docs && npm i

	@printf "${YELLOW}---------------- Initialization ---${RESET} ${GREEN}Environment settings${RESET}\n\n"

	rsync --ignore-existing .spec.env.json.example .spec.env.json

	@printf "\n\n${YELLOW}---------------- Done.${RESET}\n\n"


# DEVELOPMENT
# ~~~~~~~~~~~
# The following rules can be used during development in order to compile things, generate locales,
# build documentation, etc.
# --------------------------------------------------------------------------------------------------

.PHONY: docs
## Builds the documentation.
docs: docs_api docs_site

.PHONY: docs_api
docs_api:
	crystal docs --output=docs/static/api/dev
	cp -R docs/static/api/dev/ docs/static/api/0.2
	cp -R docs/static/api/dev/ docs/static/api/0.3
	cp -R docs/static/api/dev/ docs/static/api/0.4

.PHONY: docs_site
docs_site:
	cd docs && npm run build


# QUALITY ASSURANCE
# ~~~~~~~~~~~~~~~~~
# The following rules can be used to check code quality and perform sanity checks.
# --------------------------------------------------------------------------------------------------

.PHONY: qa
## Trigger all quality assurance checks.
qa: format_checks lint

.PHONY: format
## Perform and apply crystal formatting.
format:
	crystal tool format

.PHONY: format_checks
## Trigger crystal formatting checks.
format_checks:
	crystal tool format --check

.PHONY: lint
## Trigger code quality checks.
lint:
	bin/ameba


# TESTING
# ~~~~~~~
# The following rules can be used to trigger tests execution and produce coverage reports.
# --------------------------------------------------------------------------------------------------

.PHONY: t tests
## Alias of "tests".
t: tests
## Run all the test suites.
tests:
	crystal spec --error-trace


# MAKEFILE HELPERS
# ~~~~~~~~~~~~~~~~
# The following rules can be used to list available commands and to display help messages.
# --------------------------------------------------------------------------------------------------

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

.PHONY: help
## Print Makefile help.
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<action>${RESET}'
	@echo ''
	@echo 'Actions:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)-30s${RESET}\t${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort -t'|' -sk1,1
