# PyAlembic Build Script for Windows

build script for [Alembic](https://github.com/alembic/alembic).

## Prerequisites

- Visual Studio (MSVC)
- CMake
- Python3
- Git

## Build

Modify the `build.ps1` file.

- set the `$PythonRoot` to the Python install directory.

Run the build script.

```powershell
PS C:\builds\pyalembic-windows-buildscript> .\build.ps1 | Tee-Object build.log
```

## Use PyAlembic

```python
import os
BUILD_ROOT = r"C:\builds\pyalembic-windows-buildscript"
os.add_dll_directory(rf"{BUILD_ROOT}\boost\stage\lib")
os.add_dll_directory(rf"{BUILD_ROOT}\Imath\_installed\bin")
os.add_dll_directory(rf"{BUILD_ROOT}\alembic\_installed\lib")

import alembic
arch = alembic.Abc.OArchive("hoge.abc")
assert os.path.exists("hoge.abc")
```
