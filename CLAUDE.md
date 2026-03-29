# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Build script for PyAlembic (Alembic Python bindings) on Windows, outputting `.whl` packages.

## Build

```powershell
.\build.ps1 -PythonRoot "C:\Program Files\Python311" | Tee-Object build.log
```

Stages can be skipped individually: `-SkipBoost`, `-SkipImath`, `-SkipAlembic`, `-SkipPackaging`, `-SkipInstall`.

Output: `dist/*.whl`

## CI

`.github/workflows/build.yml` — manual trigger, builds Python 3.9–3.13 on Windows x64. Set `runReleaseAction` to create a GitHub Release.

## Key Notes

- Imath is pinned to commit `84f9a67` to avoid a build error introduced by PR #361. Updating Imath requires verifying PyAlembic still builds.
- `setup.py` dynamically reads metadata from the cloned `alembic/setup.py` at build time.
- Boost.Python must be linked as a shared DLL (not static) because PyImath and Alembic both use the same Boost.Python type registry, which cannot be shared across DLL boundaries with static linking. The wheel bundles `boost_python*.dll` alongside the other DLLs.
- `BOOST_ALL_NO_LIB` is passed as a compile flag to disable Boost's Windows auto-link feature, ensuring the explicitly-specified shared library is used instead of the auto-linked one.
