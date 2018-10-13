function Start-Build {
    $versions = 3,5
    $srcBase = Join-Path $PsScriptRoot src
    foreach ( $version in $versions ) {
        try {
            $srcDir = Join-Path $srcBase $version
            Push-Location $srcDir
            dotnet restore
            dotnet build --configuration Release
        }
        finally {
            Pop-Location
        }
    }

    # push into dotnetTemplate and build
    try {
        $templateBase = Join-Path $srcBase dotnetTemplate
        Push-Location $templateBase
        dotnet restore
        dotnet build --configuration Release
    }
    finally {
        Pop-Location
    }
}

function Start-Clean {
    $dirs = "src","test"
    $versions = 3,5
    # clean up test/3. test/5, src/3, src/5
    foreach ( $directory in $dirs ) {
        $baseDir = Join-Path $PsScriptRoot $directory
        foreach ( $version in $versions ) {
            try {
                $fileDir = Join-Path $baseDir $version
                Push-Location $fileDir
                dotnet clean
                if ( test-path obj ) { remove-item -recurse -force obj }
                if ( test-path bin ) { remove-item -recurse -force bin }
                remove-item "PowerShellStandard.Library.${version}*.nupkg" -ErrorAction SilentlyContinue
            }
            finally {
                Pop-Location
            }
        }
    }
    Remove-Item "${PSScriptRoot}/*.nupkg"
}

function Invoke-Test {
    $versions = 3,5
    foreach ( $version in $versions ) {
        try {
            $testBase = Join-Path $PsScriptRoot "test/${version}"
            Push-Location $testBase
            dotnet build --configuration Release
            Invoke-Pester
        }
        finally {
            Pop-Location
        }
    }

    try {
        Push-Location (Join-Path $PsScriptRoot "test/dotnetTemplate")
        Invoke-Pester
    }
    finally {
        Pop-Location
    }
}

function Export-NuGetPackage
{
    # create the package
    # it will automatically build
    $versions = 3,5
    $srcBase = Join-Path $PsScriptRoot src
    foreach ( $version in $versions ) {
        try {
            $srcDir = Join-Path $srcBase $version
            Push-Location $srcDir
            $result = dotnet pack --configuration Release
            if ( $? ) {
                Copy-Item -verbose:$true (Join-Path $srcDir "bin/Release/PowerShellStandard.Library*.nupkg") $PsScriptRoot
            }
            else {
                Write-Error -Message "$result"
            }
        }
        finally {
            Pop-Location
        }
    }
    # Create the template nupkg
    try {
        $templateDir = Join-Path $PsScriptRoot src/dotnetTemplate
        Push-Location $templateDir
        $result = dotnet pack --configuration Release
        if ( $? ) {
            Copy-Item -verbose:$true (Join-Path $templateDir "bin/Release/*.nupkg") $PsScriptRoot
        }
        else {
            Write-Error -Message "$result"
        }
    }
    finally {
        Pop-Location
    }

}
