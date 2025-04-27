param (
    [string]$BoostZipUrl = "https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-b2-nodocs.zip",
    [string]$BoostZipExtractedName = "boost-1.87.0",
    [string]$PythonRoot = "${env:USERPROFILE}\.pyenv\pyenv-win\versions\3.10.8",
    [switch]$SkipBoost,
    [switch]$SkipImath,
    [switch]$SkipAlembic,
    [switch]$SkipPackaging,
    [switch]$SkipInstall
)

Write-Output "Start ($(Get-Date))"
Write-Output "PythonRoot: '$PythonRoot'"

$ProgressPreference = 'SilentlyContinue'

$PythonRoot = $PythonRoot -replace "\\", "/" # replace backslashes
$PythonExe = "$PythonRoot/Python.exe"

$BoostZipName = $BoostZipUrl.Split("/")[-1]
$BoostZipDestName = "boost"

# Build boost
if (-Not $SkipBoost) {
    # Download zip
    if (!(Test-Path $BoostZipName)) {
        Write-Output "Download: '$BoostZipUrl'"
        Invoke-WebRequest -Uri $BoostZipUrl -OutFile $BoostZipName   
    }
    
    # Extract zip
    if (!(Test-Path $BoostZipDestName)) {
        Write-Output "Unzip: '$BoostZipName'"
        Expand-Archive -Path $BoostZipName -DestinationPath . -Force
    
        Write-Output "Move: '$BoostZipExtractedName' -> '$BoostZipDestName'"
        Move-Item $BoostZipExtractedName $BoostZipDestName
    }

    Push-Location boost

    try {
        .\bootstrap.bat
        Write-Output "using python : : $PythonRoot ;" > user-config.jam
        .\b2 --build-type=complete --variant=release --with-python --user-config=user-config.jam
    }
    finally {
        Pop-Location
    }
}

# Build imath
if (-Not $SkipImath) {
    git clone https://github.com/AcademySoftwareFoundation/Imath

    Push-Location Imath
    try {
        # The commit below from the Imath repo causes a PyAlembic build error:
        #
        #   src/python/config: do not install a cmake file exporting targets for dependent projects #361
        #   https://github.com/AcademySoftwareFoundation/Imath/pull/361/commits/e79adb7e9e2876243b67a59828b3651f4e187781
        #
        # Checkout the previous commit to avoid the error.
        git checkout 84f9a674802f6c3197bd478c9b40399f451fecb3
    }
    finally {
        Pop-Location
    }

    & $PythonExe -m pip install numpy

    if (!(Test-Path Imath/build)) { mkdir Imath/build }
    Push-Location Imath/build

    try {
        cmake .. -DPython_EXECUTABLE="$PythonExe" -DPython3_EXECUTABLE="$PythonExe" -DPYTHON=ON -DBoost_ROOT="../../$BoostZipDestName" -DCMAKE_INSTALL_PREFIX="../_installed"
        cmake --build . --config Release
        cmake --install .
    }
    finally {
        Pop-Location
    }
}

# Build alembic
if (-Not $SkipAlembic) {
    git clone https://github.com/alembic/alembic
    if (!(Test-Path alembic/build)) { mkdir alembic/build }
    Push-Location alembic/build

    try {
        cmake .. -DUSE_PYALEMBIC=ON -DImath_DIR="../Imath/_installed/lib/cmake/Imath" -DPython3_EXECUTABLE="$PythonExe" -DBoost_ROOT="../../$BoostZipDestName" -DCMAKE_INSTALL_PREFIX="../_installed" -DALEMBIC_PYTHON_INSTALL_DIR="../_installed/lib/site-packages"
        cmake --build . --config Release
        cmake --install .
    }
    finally {
        Pop-Location
    }
}

# Create wheel package
if (-Not $SkipPackaging) {
    & $PythonExe setup.py bdist_wheel
}

# Install wheel package
if (-Not $SkipInstall) {
    foreach ($file in (Get-ChildItem -File "dist\*.whl")) {
        & $PythonExe -m pip install $file --upgrade --force-reinstall
    }

    # Test module import
    & $PythonExe -c "import alembic"
}

Write-Output "End ($(Get-Date))"