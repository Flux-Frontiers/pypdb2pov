#
# Makefile for pypdb2pov.
#
# Copyright (c) 1993-2026 Eric G. Suchanek, Ph.D.
# Subject to the GNU License.
#
# There is nothing to build -- the package is pure Python with no runtime
# dependencies.  Most of what a Makefile used to do here now lives elsewhere:
# ruff, ty and pytest run from .pre-commit-config.yaml on every commit and
# again in .github/workflows/ci.yml, and the wheel is built and smoke-tested
# by the `wheel` CI job.  What is left is the setup step, a fast inner-loop
# test, and the conversion smoke test that nothing else performs.
#
# Setup:
#   poetry install --with dev     the test, lint and type toolchain
#   poetry install --with kg      adds the pycodekg and dockg CLIs
#   make hooks                    install the pre-commit hooks
#
# Targets:
#   make test       the suite, directly -- the fast inner loop
#   make lint       every pre-commit hook over the whole tree
#   make check      test, then convert the bundled structures
#   make hooks      install the git pre-commit hooks
#   make clean      remove caches, build output, and check artefacts
#

# The venv binaries directly, never `poetry run`: `poetry run` resolves against
# whatever VIRTUAL_ENV the calling shell advertises, so an inherited value from
# another repo silently redirects the command.  Same rule the pre-commit hooks
# follow -- see kgrag_priv/docs/FLEET_STANDARDS.md.
BIN      = .venv/bin
PYTHON  ?= $(BIN)/python
SRC      = src
DATA     = tests/data
RUN      = PYTHONPATH=$(SRC) $(PYTHON) -m pypdb2pov

.PHONY: all test lint check hooks clean

all: test

test:
	$(BIN)/pytest -q

#
# ruff, ty and pytest all at once, over every file rather than the staged
# ones.  This is exactly what the commit hook runs, so a green result here
# means the commit will not be rejected.
#
lint:
	$(BIN)/pre-commit run --all-files

hooks:
	$(BIN)/pre-commit install

#
# The one check neither the hooks nor CI perform: actually convert something
# and look at what came out.  Every element in the table must resolve to its
# own texture -- an Atom_X in the element scene means one fell through.
#
check: test
	@echo "--- converting the bundled structures ---"
	$(RUN) $(DATA)/1CRN.pdb check_py_vdw -v -p --quiet
	$(RUN) $(DATA)/1CRN.pdb check_py_bs  -b -d 1.9 -p --quiet
	$(RUN) $(DATA)/1CRN.pdb check_py_obj -b -d 1.9 -o --quiet
	$(RUN) $(DATA)/elements.pdb check_py_elements -v -p --quiet
	@ls -l check_py_*.pov check_py_obj.inc
	@echo "--- every element must resolve to its own texture ---"
	@if grep -qE 'Atom_X\b' check_py_elements.pov; then \
	  echo "FAIL: an element in the table has no dedicated texture"; exit 1; \
	else \
	  echo "OK: every element resolved to its own texture"; \
	fi

clean:
	rm -f check_py_*.pov check_py_*.inc
	rm -rf .pytest_cache .ruff_cache dist build src/*.egg-info
	find . -name __pycache__ -type d -prune -exec rm -rf {} +
