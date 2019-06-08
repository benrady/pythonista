SHELL := $(shell which bash) # Use bash instead of bin/sh as shell
SYS_PYTHON := $(shell which python3 || echo ".python_is_missing")
VENV = .venv
PYTHON := $(VENV)/bin/python3
PIP := $(VENV)/bin/pip
LOG_LEVEL := INFO
PROJECT_NAME := $(shell basename $(PWD))
DEPS := $(VENV)/.deps 

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

$(SYS_PYTHON): 
	@$(error "You need Python 3. I can't find it on the PATH.")

$(VENV): $(SYS_PYTHON)
	@$(SYS_PYTHON) -m venv $(VENV)

$(DEPS): requirements.txt | $(VENV)
	@$(PIP) install -r requirements.txt
	@cp requirements.txt $(DEPS)

.PHONY: run test

clean: ## Remove pycache files
	@find . -name __pycache__ | grep -v venv | xargs rm -rf

git-deploy: $(DEPS) # Called by the git-deploy plugin during a push
	@ln -s -f -T ${PWD} ~/service/$(PROJECT_NAME)

test: $(DEPS) # Run all unit and integration tests once
	@$(PYTHON) -m pytest

run: $(DEPS) ## Start the service in dev mode
	@LOG_LEVEL=DEBUG $(PYTHON) main.py

test-dbg: $(DEPS) ## Run tests the python debugger
	@$(PYTHON) -m pytest $(PYTEST_OPTS) --pdb

watch: $(DEPS) ## Run tests and linter continuously
	@PYTHONPATH=. $(PYTHON) -m pytest_watch -n

lint: $(DEPS) ## Runs tests, linting, and pep8 formatting
	@$(VENV)/bin/pylint $(PROJECT_NAME) test

repl: $(DEPS)
	@$(VENV)/bin/ipython -i main.py

