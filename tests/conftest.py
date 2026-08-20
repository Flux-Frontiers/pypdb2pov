"""Shared fixtures: the test data directory and the structures inside it."""

from __future__ import annotations

import os

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")


@pytest.fixture(scope="session")
def data_dir() -> str:
    return DATA


@pytest.fixture(scope="session")
def crambin_pdb() -> str:
    """
    The wwPDB's 1CRN, vendored into ``tests/data``.

    Crambin is the structure every numeric expectation in the suite is pinned
    to -- the camera distance, the enclosing radius, the bond count -- so it
    ships with the package rather than being looked for elsewhere on disk.
    """
    return os.path.join(DATA, "1CRN.pdb")


@pytest.fixture(scope="session")
def elements_pdb() -> str:
    """One synthetic atom per element with a dedicated POV-Ray texture."""
    return os.path.join(DATA, "elements.pdb")
