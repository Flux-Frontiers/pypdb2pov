[![Python](https://img.shields.io/badge/python-3.12%20%7C%203.13-blue.svg)](https://www.python.org/)
[![License: BSD 3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.1-blue.svg)](https://github.com/Flux-Frontiers/pypdb2pov/releases)
[![PyPI](https://img.shields.io/pypi/v/pypdb2pov.svg)](https://pypi.org/project/pypdb2pov/)
[![CI](https://github.com/Flux-Frontiers/pypdb2pov/actions/workflows/ci.yml/badge.svg)](https://github.com/Flux-Frontiers/pypdb2pov/actions/workflows/ci.yml)

# pypdb2pov -- PDB and mmCIF Structures as POV-Ray Scenes

**pypdb2pov turns Brookhaven PDB and PDBx/mmCIF atomic structure files into
POV-Ray scenes -- space-filling, ball-and-stick, or glass -- from one command
or from Python.**

It reads mmCIF, so structures too large for the PDB format render at all; it
opens `.gz`, `.bz2` and `.xz` with no decompression step; its bond search is
linear rather than quadratic, so fifty thousand atoms takes under a second; it
infers elements from the atom name the way the format specifies rather than
guessing from the first letter; and nothing is ever dropped in silence --
skips, ambiguities and untextured atoms are all counted and reported with line
numbers.

It is a Python port of `pdb2pov`, the 1993 C program by the same author, and
keeps that program's command-line vocabulary so existing invocations still mean
what they meant. Everything else here is new.

It is also a library. `read_structure` returns a plain list of `Atom`
dataclasses carrying everything the readers recover, which makes it usable as a
PDB/mmCIF reader in its own right and not only as a step towards a scene.

No dependencies beyond the standard library. The POV-Ray include files ship
inside the package, so a `pip install` is the whole setup.

*Author: Eric G. Suchanek, PhD -- Flux-Frontiers, Liberty TWP, OH*

---

## Sister projects

- **[quiltwright](https://github.com/Flux-Frontiers/quiltwright)** -- renders
  these scenes as multi-view quilts for Looking Glass holographic displays.
- **[proteusPy](https://github.com/suchanek/proteusPy)** -- the same idea again,
  targeting VTK rather than a ray tracer.
- **[KGRAG](https://github.com/Flux-Frontiers/KGRAG)** -- the knowledge-graph
  federation layer the rest of the Flux-Frontiers stack is built on.

---

## Installation

```sh
pip install pypdb2pov
```

From a checkout, for development:

```sh
poetry install --with dev    # pytest, ruff, ty
poetry install --with kg     # adds the pycodekg and dockg CLIs
```

The maintainer toolchain lives in Poetry groups, not extras, so it is never
written into the published wheel -- `pip install pypdb2pov` pulls nothing at
all. `pip install pypdb2pov[dev]` is deliberately not a thing.

Or don't install it at all -- the package has no dependencies, so
`PYTHONPATH=src python3 -m pypdb2pov ...` works straight from a clone.

Python 3.12 or newer.

---

## Quick start

```
pypdb2pov InputFile OutputFile [options]
```

```sh
pypdb2pov crambin crambin -s -h -b -d 1.5 -x 90
```

Filenames may be given without extensions, as they always could -- `.pdb` (or
`.cif`, `.ent`, `.atm`, or a compressed variant) is appended to the input and
`.pov`/`.inc` to the output. A path that exists as given is used as given, so
`4hhb.cif.gz` works too. `-` is standard input or standard output.

> **`-h` is the checkered ground, not help.** It has meant that since 1993 and
> still does, so `--help` prints the usage message instead.

### Scene, radii and geometry

| Flag | Effect |
|------|--------|
| `-v` | van der Waals radii (default) |
| `-c` | covalent radii |
| `-b` | ball and stick |
| `-q` | ball and stick with glass atoms |
| `-d x.x` | bond cutoff threshold in ångströms (default 2.2) |
| `-r x.x` | scale factor applied to all atomic radii |
| `-o` | object only -- write a `.inc` with no camera or lights |
| `-p` | plain white sky, no ground |
| `-s` | cloudy sky |
| `-g` | plain ground |
| `-h` | checkered ground |
| `-a` | area light instead of a point light |
| `-x -y -z` | absolute rotation about each axis, in degrees |
| `-t` | input is in `.atm` format |
| `--chain IDS` | restrict to the given chain IDs |
| `--keep-altlocs` | keep every alternate conformation |
| `--legacy-elements` | guess elements from atom names, first-letter style |

### Input, filtering and reporting

| Flag | Effect |
|------|--------|
| `--format {auto,pdb,cif,atm}` | override format detection |
| `--model N` | convert model N (default: the first in the file) |
| `--all-models` | convert every model at once |
| `--altloc {a,first,occupancy,all}` | how to resolve alternate conformations |
| `--no-hetatm`, `--no-water` | drop heteroatoms or waters without pre-filtering |
| `--bonds {distance,covalent}` | bond by one cutoff, or by covalent radii |
| `--bond-tolerance x.x` | slack added to the radius sum in covalent mode |
| `--strict` | fail on an unparseable record instead of skipping it |
| `--name IDENT` | POV-Ray identifier for the declared objects |
| `--no-timestamp` | omit the date, so two runs are byte-identical |
| `--info` | report what the file contains and write nothing |
| `--include-dir` | print where the bundled `.inc` files live |
| `--list-elements` | print the elements with a dedicated texture |
| `--quiet` | only report problems |

---

## What it does

### It reads mmCIF

The PDB format ran out of room years ago -- five columns for a serial number,
one for a chain -- so anything above 99,999 atoms or 62 chains is distributed
only as PDBx/mmCIF. Ribosomes, capsids and large complexes are mmCIF-only.

```sh
pypdb2pov 6xyz.cif.gz capsid -b -o
```

The reader handles the `_atom_site` loop with the syntax wwPDB files actually
use: quoted values, semicolon-delimited text blocks, nulls, and multiple
models. `auth_*` columns are preferred over `label_*` where both exist, so
`--chain A` means the chain the literature calls A.

### It opens compressed files

`.gz`, `.bz2` and `.xz` are read transparently, which is how the wwPDB ships
them. No decompression step, no temporary file.

### It understands models

`MODEL`/`ENDMDL` are parsed as records. The default is the first model in the
file, `--model N` picks another, and `--all-models` converts every one. This
matters for NMR ensembles, where a naive reader stops at the first line
beginning `END` -- which happens to be `ENDMDL` -- and can never reach model 7.

### It infers elements properly

Elements come from columns 77-78 when they are there. When they are not -- the
file predates the column -- the atom name is read the way the format specifies
rather than switched on its first letter:

| Record | Residue | First-letter guess | pypdb2pov |
|--------|---------|--------------------|-----------|
| ` NA ` | `HEM` | **sodium** | nitrogen (haem N-alpha) |
| ` CD ` | `GLU` | carbon | carbon (glutamate C-delta) |
| ` CD ` | ligand | carbon | cadmium, if column-aligned as one |
| `ZN  ` | `ZN` | *dropped* | zinc |
| `FE  ` | `HEM` | iron | iron |
| `SE  ` | `MSE` | *dropped* | selenium |

Three rules do the work, in order: an atom name that matches its residue name
and is an element symbol is that element (`ZN`/`ZN`); inside a standard residue
the element is the leading letter, full stop; otherwise the column alignment
decides, because the format right-justifies a two-letter symbol into columns
13-14.

Where the answer is genuinely ambiguous -- a hand-edited ` FE ` sitting in
column 14, where the format says one-letter -- the column rule wins and the
conversion **says so**:

```
  1 atom name(s) read by the PDB column rule where a two-letter element was
    also possible ('FE' as F not FE);
      add an element column in 77-78, or use --legacy-elements, to override
```

`--legacy-elements` restores the first-letter guess exactly, mistakes included,
for reproducing a render made with it.

### It gives alternate conformations a policy

| `--altloc` | Behaviour |
|------------|-----------|
| `a` | keep the blank and `A` indicators -- the historical default |
| `first` | keep whichever indicator comes first for each atom |
| `occupancy` | keep the highest-occupancy conformer, the crystallographer's answer |
| `all` | keep every conformation |

`a` loses a residue entirely when a depositor labels its conformers `B` and `C`
with no `A`. `first` does not, and is otherwise identical on conventionally
ordered files. In 1CBN that is fourteen atoms -- the side chains of Pro 22 and
Leu 25 -- silently absent under `a`.

The choice is made **per residue**, which matters for microheterogeneity: in
that same entry residue 22 is modelled as serine at 0.20 occupancy *and*
proline at 0.60, sharing one sequence position. Choosing atom by atom would
take proline's ring and serine's hydroxyl from the same place and draw a
residue that does not exist. `--altloc occupancy` picks the proline, whole.

### The bond search is linear, not quadratic

Comparing every pair of atoms is fine for crambin's 327 and hopeless above
about ten thousand. Atoms go into a uniform grid of cells one cutoff wide, so
each looks only at the 27 cells around it. 50,000 atoms takes well under a
second.

The grid returns exactly what the pairwise scan returns, in the same order --
the traversal order the hydrogen rule depends on is preserved deliberately, and
`tests/test_bonds.py` diffs the two over random structures.

`--bonds covalent` adds what a single cutoff cannot express -- a 1.1 Å C-H and
a 2.05 Å disulphide in the same structure, without also bonding every carbon to
its neighbour's neighbour.

### Nothing is dropped silently, and problems have line numbers

```
Scanning atom file <4hhb.pdb>... got <4779> atoms.
  216 atom(s) in alternate conformations skipped (--keep-altlocs to keep them)
  2 unparseable coordinate record(s) skipped
      line 1841: ATOM   1839  CB  SER A 234      ????    ????   ????
  4 atom(s) have no dedicated texture and render as Atom_X (GD, RU)
```

`--strict` turns the skip into a failure. `--info` reports the same census
without writing anything.

### No fixed limits

No line buffer, no pre-counted atom array, no pre-count pass. Files are read
once, and a long record is a long record rather than two short ones.

---

## Library use

```python
from pypdb2pov import convert

convert("1crn.pdb", "crambin", ball_stick=True, bond_threshold=1.9)
```

or, with the pieces exposed:

```python
from pypdb2pov import (
    ParseOptions, SceneOptions, read_structure,
    find_bonds, prepare_structure, write_scene,
)

structure, stats = read_structure("4hhb.cif.gz", ParseOptions(chains="A"))
print(structure.title, len(structure), structure.element_counts())

options = SceneOptions(ball_stick=True, object_only=True, name="hemoglobin_a")
prepare_structure(structure, options)                    # rotate, centre, flip
bonds = find_bonds(structure, options.bond_threshold)
write_scene(structure, options, "hemoglobin_a.inc", bonds)
```

`Structure` is a plain list of `Atom` dataclasses carrying everything the
readers recover -- name, element, residue, chain, insertion code, altLoc,
occupancy, B-factor, formal charge, model.

---

## Rendering

Scenes reference the bundled include files by name, so POV-Ray needs the
directory on its library path:

```sh
povray +Icrambin.pov +W800 +H600 +A0.3 -D +L"$(pypdb2pov --include-dir)"
```

The includes are shipped inside the package, which is what makes an install
self-contained.

---

## Development

```sh
poetry install --with dev
make hooks         # install the pre-commit hooks
make test          # the suite -- the fast inner loop
make lint          # every hook over the whole tree: ruff, ty, pytest
make check         # test, then convert the bundled structures
```

ruff, ty and pytest run on every commit through
[.pre-commit-config.yaml](.pre-commit-config.yaml) and again in CI, so `make`
carries only the setup step and the conversion smoke test nothing else does.

102 tests, no network, no fixtures outside `tests/data`. The numeric
expectations are pinned to crambin, which ships with the suite: the camera
distance quiltwright documents at 40.075, the enclosing sphere at 18.759, and
the bond count. Both constants fall out of the deliberately truncated
degree-to-radian values the C used, and both are reproduced here.

---

## Differences from the C, in full

Everything here is deliberate. Nothing else differs.

| Area | C 2.2 | Python |
|------|-------|--------|
| Scene output | -- | the same, except the `Prepared by` line, which names this package and the source file |
| Element inference with no element column | seven-letter first-character guess | column- and residue-aware, with ambiguity reported |
| `.atm` element handling | first-character guess | the same inference as PDB; `--legacy-elements` restores the guess |
| Formats | PDB, `.atm` | plus mmCIF, plus `.gz`/`.bz2`/`.xz`, plus stdin |
| Models | first `END`-prefixed line ends the read | `MODEL`/`ENDMDL`, `--model`, `--all-models` |
| Bond search | O(N²), twice | O(N) via a grid, same results and order |
| Line length | 256 bytes, longer lines split | unbounded |
| Atom count | pre-counted, fixed array | unbounded |
| Exit statuses | 0/2/3/4/5/6 | the same |
| Command name | `pdb2pov` | `pypdb2pov` |

The `-t` `.atm` path is the one place a *default* differs in output: the format
has no element column, and the port infers elements there the same way it does
for PDB rather than falling back to the 1993 guess. Pass `--legacy-elements`
for the old behaviour.

---

## Citation

If you use pypdb2pov in research or a project, please cite it:

**APA**

> Suchanek, E. G. (2026). *pypdb2pov: PDB and mmCIF Structures as POV-Ray
> Scenes* (Version 0.1.1) [Software]. Flux-Frontiers.
> https://github.com/Flux-Frontiers/pypdb2pov

**BibTeX**

```bibtex
@software{suchanek_pypdb2pov,
  author    = {Suchanek, Eric G.},
  title     = {{pypdb2pov}: PDB and mmCIF Structures as POV-Ray Scenes},
  version   = {0.1.1},
  year      = {2026},
  publisher = {Flux-Frontiers},
  url       = {https://github.com/Flux-Frontiers/pypdb2pov},
}
```

---

## License

[BSD 3-Clause License](LICENSE).
Copyright (c) 1993-2026 Eric G. Suchanek, Ph.D.

---

## Support

- **Issues** -- [GitHub Issues](https://github.com/Flux-Frontiers/pypdb2pov/issues)
- Sister projects: [quiltwright](https://github.com/Flux-Frontiers/quiltwright),
  [KGRAG](https://github.com/Flux-Frontiers/KGRAG)
- Built on the Python standard library, and on POV-Ray

---

*Thirty-three years of molecular graphics, still one command -- egs*
