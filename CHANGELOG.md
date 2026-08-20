# Changelog

All notable changes to pypdb2pov are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- **The license is BSD 3-Clause, which is what `LICENSE` said all along.**
  The file has carried the BSD 3-Clause text since the repository was
  created; every declaration around it said GPL-2.0-or-later. The metadata,
  the README badge and License section, and the `Makefile` and
  `pypdb2pov/__init__.py` headers now agree with the file they point at, and
  the built wheel declares `License-Expression: BSD-3-Clause` with the text
  at `dist-info/licenses/LICENSE`.

- **The package builds with poetry-core rather than setuptools**, so
  `poetry build` is the one build command here and across the fleet, and the
  `wheel` CI job no longer installs `build` to invoke a second one. This was
  the only fleet repo on a different backend.

  `[tool.setuptools.packages.find]` and `[tool.setuptools.package-data]` are
  replaced by a single `[tool.poetry] packages` entry. poetry-core ships
  every non-ignored file inside the package directory, so the bundled
  `include/*.inc` textures need no declaration of their own -- all five land
  in the wheel and the sdist, which the `wheel` job proves by installing the
  artifact into a clean virtualenv where no source tree is in sight.

- **Packaging metadata names the author as the rest of the fleet does**:
  `Eric G. Suchanek, PhD` with an email, where the wheel previously carried
  no `Author-email` at all. `pyproject.toml` also gains the fleet's
  `Author:` / `License:` header block, without the `Last Revision:` line
  that the fleet retired.

- **The README reads as a Python tool with a lineage, rather than as a port
  defined by its ancestor.** It led with "a faithful Python port of `pdb2pov`
  2.2" and explained several behaviours by describing what the C did instead
  of what this does. The lineage is stated once, plainly -- a Python port of
  the 1993 C program by the same author, keeping its command-line vocabulary
  -- and the rest describes the tool.

  `What the port improves` is now `What it does`; the flag tables split by
  what the flags are (`Scene, radii and geometry` / `Input, filtering and
  reporting`) rather than by which era introduced them; and the element
  table's `Pre-2.1 guess` column is `First-letter guess`. The
  `Differences from the C, in full` table stays -- the heritage is real and
  worth recording -- minus the note about both commands sharing a `PATH`.

### Removed

- **`PDB2POV_VERSION`**, and the second version number it carried. The package
  tracked its own version alongside the pdb2pov release whose scenes it wrote,
  and named both in every scene header and in `--version`. The distinction was
  bookkeeping for a C program that is no longer in the picture: this is a
  Python package with one version.

  Scene headers lose the parenthesis -- `// Prepared by pypdb2pov 0.1.0 from
  1CRN.pdb on ...` rather than `... 0.1.0 (pdb2pov 2.2) from ...` -- and
  `--version` prints `pypdb2pov 0.1.0`. The constant is gone from the public
  API, which drops from 40 names to 39.

## [0.1.0] - 2026-08-19

First release of the Python port. The C program's behaviour is reproduced
deliberately -- every flag means what it has meant since 1993 -- and
everything below the "Added" heading is what the port adds on top of it.

### Added

- **The package.** `pypdb2pov` reads Brookhaven PDB, PDBx/mmCIF and `.atm`
  files and writes POV-Ray scenes. No dependencies beyond the standard
  library; the POV-Ray texture includes ship inside the package, so an
  install is the whole setup and `--include-dir` reports where they landed.

- **mmCIF support.** The PDB format runs out of room at 99,999 atoms and 62
  chains, so anything larger is distributed only as PDBx/mmCIF, which
  `pdb2pov.c` cannot read at all. The `_atom_site` loop is parsed with the
  syntax wwPDB files actually use: quoted values, semicolon-delimited text
  blocks, nulls and multiple models. `auth_*` columns are preferred over
  `label_*` where both exist, so `--chain A` selects the chain the literature
  calls A.

- **Transparent decompression.** `.gz`, `.bz2` and `.xz` are read directly,
  which is how the wwPDB ships them. `-` reads standard input or writes
  standard output.

- **Model selection.** `MODEL`/`ENDMDL` are parsed as records. The C stopped
  at the first line beginning `END`, which happens to be `ENDMDL` -- the
  right answer for an NMR ensemble reached by the wrong route, with no way to
  ask for model 7. `--model N` picks one, `--all-models` keeps them all.

- **Column- and residue-aware element inference.** Where the element column
  is absent, the atom name is read the way the format specifies rather than
  by switching on its first letter. ` NA ` in a haem is nitrogen, not sodium;
  `ZN` in a `ZN` residue is zinc rather than being dropped. Genuinely
  ambiguous names are resolved by column alignment and the ambiguity is
  reported. `--legacy-elements` restores the 1993 guess exactly, mistakes
  included, for reproducing an existing render.

- **An alternate-conformation policy.** `--altloc {a,first,occupancy,all}`.
  The choice is made per residue, not per atom, which is what
  microheterogeneity requires: choosing atom by atom would take proline's
  ring and serine's hydroxyl from one sequence position and draw a residue
  that does not exist.

- **Linear bond search.** Atoms go into a uniform grid of cells one cutoff
  wide, so each examines only the 27 cells around it, replacing the C's two
  full O(N^2) passes. 50,000 atoms completes in well under a second. The
  results are identical pair for pair and in the same order -- the traversal
  order the hydrogen rule depends on is reproduced deliberately, and
  `tests/test_bonds.py` diffs the grid against a transcription of the C loop
  over random structures.

- **`--bonds covalent`**, bonding by the sum of covalent radii plus
  `--bond-tolerance`, which expresses what a single cutoff cannot: a 1.1 A
  C-H and a 2.05 A disulphide in one structure.

- **Reporting instead of silence.** Skipped records, dropped conformations,
  untextured atoms and ambiguous elements are all counted and reported with
  line numbers. `--strict` turns a skip into a failure; `--info` reports the
  census without writing anything.

- **A library API.** `convert()` for the one-line case, or `read_structure`,
  `prepare_structure`, `find_bonds` and `write_scene` separately.
  `Structure` is a list of `Atom` dataclasses carrying name, element,
  residue, chain, insertion code, altLoc, occupancy, B-factor, formal charge
  and model, which makes it usable as a PDB/mmCIF reader in its own right.

- **New flags:** `--format`, `--name`, `--no-timestamp`, `--no-hetatm`,
  `--no-water`, `--list-elements`, `--quiet`.

### Changed

- **No fixed limits.** The C read into a 256-byte line buffer and a
  pre-counted fixed-size array, silently splitting any longer line into two
  records. There are no buffers and no pre-count pass; files are read once.

- **`-t` (`.atm`) elements** are inferred the same way as PDB rather than by
  the 1993 first-character guess. This is the one place a default differs in
  output; `--legacy-elements` restores the old behaviour.

- **The command is `pypdb2pov`,** not `pdb2pov`, so the port and the C
  program can share a `PATH`.

### Infrastructure

- **CI** (`.github/workflows/ci.yml`) -- lint, type-check, test, and a
  `wheel` job that builds the artifact users actually receive, installs it
  into a venv with no source tree in sight, loads every console-script entry
  point, and asserts the bundled `include/*.inc` textures shipped as package
  data. None of that is observable from the source tree, and shipping a wheel
  whose console scripts are dead on `pip install` is a documented fleet
  failure mode.

- **Release** (`.github/workflows/release.yml`) -- tag-triggered build,
  `twine check`, GitHub Release, and PyPI upload via trusted publishing. The
  PyPI publisher must be configured once before the first tag.

- **Pre-commit hooks** -- ruff, ty, pytest and detect-secrets. Local entries
  call `.venv/bin/` directly rather than `poetry run`, per
  `kgrag_priv/docs/FLEET_STANDARDS.md`. The whitespace fixers skip
  `tests/data/` and `src/pypdb2pov/include/`, which hold verbatim reference
  copies -- the wwPDB's 1CRN and the textures inherited from the C tree.

- **The maintainer toolchain lives in Poetry groups, not extras** (`dev` for
  pytest/ruff/ty/pre-commit, `kg` for the pycodekg and dockg CLIs that
  `.mcp.json` serves). An extra is written into wheel metadata, which would
  offer every consumer this repo's `ruff<0.16` cap on a package whose whole
  claim is that it has no dependencies. The `wheel` CI job fails if `dev`,
  `kg`, `all` or `full` ever reappears there.

### Removed

- **The differential tests against the C program.** They built `pdb2pov.c`
  from a sibling directory and diffed the two outputs, which cannot work now
  that the port is a stand-alone repository -- 39 of 116 tests were skipping.
  `tests/data/` now vendors the wwPDB's 1CRN and the element grid the tests
  were reaching outside the repo for, and all 102 remaining tests run.
