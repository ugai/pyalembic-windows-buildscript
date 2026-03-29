import glob
import shutil
import subprocess

from setuptools import find_packages, setup
from setuptools.command.install import install


class CustomInstallCommand(install):
    def run(self):
        super().run()

        # Copy all dependent binaries to the package directory
        GLOB_PATTERNS = [
            # *.pyd files
            "alembic/_installed/lib/site-packages/*.pyd",
            "Imath/_installed/lib/site-packages/*.pyd",
            "Imath/_installed/Lib/site-packages/*.pyd",
            # *.dll files
            "boost/stage/lib/boost_python*.dll",
            "alembic/_installed/bin/*.dll",
            "Imath/_installed/bin/*.dll",
        ]

        for pattern in GLOB_PATTERNS:
            for rel_path in glob.glob(pattern):
                if "-gd-" in rel_path:  # skip debug Boost DLLs
                    continue
                print(f"file copy: '{rel_path}' -> '{self.install_lib}'")
                shutil.copy(rel_path, self.install_lib)


def get_orig_setup_py_value(name: str) -> str:
    """Retrieve a value from the setup.py file of the original Alembic project."""
    cmd = ["python", "alembic/setup.py", f"--{name}"]
    s = subprocess.run(cmd, capture_output=True, text=True).stdout
    return s.rstrip()


def get_alembic_version() -> str:
    """Read the Alembic version from CMakeLists.txt."""
    import re
    with open("alembic/CMakeLists.txt", encoding="utf-8") as f:
        for line in f:
            m = re.search(r"PROJECT\(Alembic\s+VERSION\s+([\d.]+)\)", line)
            if m:
                return m.group(1)
    raise RuntimeError("Could not find Alembic version in CMakeLists.txt")


setup(
    name=get_orig_setup_py_value("name"),
    version=get_alembic_version(),
    author=get_orig_setup_py_value("author"),
    author_email=get_orig_setup_py_value("author-email"),
    description=get_orig_setup_py_value("description"),
    long_description=get_orig_setup_py_value("long-description"),
    install_requires=["numpy"],
    packages=find_packages(),
    include_package_data=True,
    cmdclass={"install": CustomInstallCommand},
    has_ext_modules=lambda: True,
)
