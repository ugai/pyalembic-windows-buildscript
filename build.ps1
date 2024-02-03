param (
    [string]$BoostZipUrl = "https://boostorg.jfrog.io/artifactory/main/release/1.81.0/source/boost_1_81_0.zip",
    [string]$PythonRoot = "$env:USERPROFILE\.pyenv\pyenv-win\versions\3.10.8"
)

Write-Output "Start ($(Get-Date))"
Write-Output "PythonRoot: '$PythonRoot'"

$ProgressPreference = 'SilentlyContinue'

$PythonRoot = $PythonRoot -replace "\\", "/" # replace backslashes
$PythonExe = "$PythonRoot/Python.exe"
$PythonModuleInstallDest = "$PythonRoot/Lib/site-packages"

$BoostZipName = $BoostZipUrl.Split("/")[-1]
$BoostZipNameNoExt = $BoostZipName.Substring(0, $BoostZipName.LastIndexOf('.'))
$BoostZipDestName = "boost"

# Build boost
$BuildBoost = $true
if ($BuildBoost) {
    # Download zip
    if (!(Test-Path $BoostZipName)) {
        Write-Output "Download: '$BoostZipUrl'"
        Invoke-WebRequest -Uri $BoostZipUrl -OutFile $BoostZipName   
    }
    
    # Extract zip
    if (!(Test-Path $BoostZipDestName)) {
        Write-Output "Unzip: '$BoostZipName'"
        Expand-Archive -Path $BoostZipName -DestinationPath .
    
        Write-Output "Move: '$BoostZipNameNoExt' -> '$BoostZipDestName'"
        Move-Item $BoostZipNameNoExt $BoostZipDestName
    }

    Push-Location boost
    .\bootstrap.bat
    Write-Output "using python : : $PythonRoot ;" > user-config.jam
    .\b2 --build-type=complete --with-python --user-config=user-config.jam
    Pop-Location
}

# Build imath
$BuildImath = $true
if ($BuildImath) {
    git clone https://github.com/AcademySoftwareFoundation/Imath
    if (!(Test-Path Imath/build)) { mkdir Imath/build }
    Push-Location Imath/build
    cmake .. -DPython_EXECUTABLE="$PythonExe" -DPython3_EXECUTABLE="$PythonExe" -DPYTHON=ON -DBoost_ROOT="../../$BoostZipDestName" -DCMAKE_INSTALL_PREFIX="../_installed"
    cmake --build . --config Release
    cmake --install .
    Copy-Item "../_installed/lib/site-packages/*.pyd" $PythonModuleInstallDest
    Pop-Location
}

# Build alembic
$BuildAlembic = $true
if ($BuildAlembic) {
    git clone https://github.com/alembic/alembic
    if (!(Test-Path alembic/build)) { mkdir alembic/build }
    Push-Location alembic/build
    cmake .. -DUSE_PYALEMBIC=ON -DImath_DIR="../Imath/_installed/lib/cmake/Imath" -DPython3_EXECUTABLE="$PythonExe" -DBoost_ROOT="../../$BoostZipDestName" -DCMAKE_INSTALL_PREFIX="../_installed" -DALEMBIC_PYTHON_INSTALL_DIR="../_installed/lib/site-packages"
    cmake --build . --config Release
    cmake --install .
    Copy-Item "../_installed/lib/site-packages/*.pyd" $PythonModuleInstallDest
    Pop-Location
}

Write-Output "End ($(Get-Date))"