# Changelog

All notable changes to pypdb2pov are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

Two version numbers run in parallel and mean different things.
`pypdb2pov.__version__` is this package's and is what these headings track.
`pypdb2pov.PDB2POV_VERSION` is 2.2, the pdb2pov release whose scenes the
package writes; it moves only when the scene format itself does.

## [Unreleased]

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
