# PyAlembic Build Script for Windows

This script builds [Alembic](https://github.com/alembic/alembic) and its Python bindings for Windows.

## Prerequisites

To use this script, you need to have the following software installed on your Windows machine:

- Visual Studio (MSVC)
- CMake
- Python3
- Git

## Build

To build PyAlembic, follow these steps:

1. Clone this repository to your local machine.
2. Open a PowerShell terminal and navigate to the repository folder.
3. Run the `build.ps1` script with the `-PythonRoot` option, specifying the path to your Python installation. For example:

    ```powershell
    PS C:\builds\pyalembic-windows-buildscript> .\build.ps1 -PythonRoot "$env:USERPROFILE\.pyenv\pyenv-win\versions\3.10.8" | Tee-Object build.log
    ```

A .whl file will be output to the `dist` directory.

## Usage

To use PyAlembic module in your Python scripts, import the `alembic` module. For example:

```python
import alembic

# Print a version
print(alembic.Abc.GetLibraryVersion())

# Create an .abc file
arch = alembic.Abc.OArchive("hoge.abc")
assert os.path.exists("hoge.abc")
```

For more information on how to use PyAlembic, please refer to the [official documentation](https://docs.alembic.io/python/examples.html#pyalembic-intro).

## License

This project is licensed under the CC0 license.
