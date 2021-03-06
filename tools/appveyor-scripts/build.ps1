Set-PSDebug -Trace 1
$python = "C:\\Python27\\python.exe"

Write-Host "Set environment"
# gradlew
$env:ANDROID_HOME=$env:APPVEYOR_BUILD_FOLDER + "\..\android-sdk"
$env:ANDROID_NDK_HOME=$env:APPVEYOR_BUILD_FOLDER + "\..\android-ndk-r16b"
# gen-libs
$env:ANDROID_SDK_ROOT=$env:APPVEYOR_BUILD_FOLDER + "\..\android-sdk"
$env:NDK_ROOT=$env:APPVEYOR_BUILD_FOLDER + "\..\android-ndk-r16b"

function PushAndroidArtifacts
{
    # https://www.appveyor.com/docs/packaging-artifacts/
    $root = Resolve-Path app\build\outputs\apk; [IO.Directory]::GetFiles($root.Path, '*.*', 'AllDirectories') | % { Push-AppveyorArtifact $_ -FileName $_.Substring($root.Path.Length + 1) -DeploymentName to-publish }
}


If ($env:build_type -eq "android_cpp_tests") {
    Write-Host "Build tests\cpp-tests"
    Push-Location $env:APPVEYOR_BUILD_FOLDER\tests\cpp-tests\proj.android\
    & ./gradlew assembleRelease -PPROP_BUILD_TYPE=cmake --parallel --info
    if ($lastexitcode -ne 0) {throw}
    PushAndroidArtifacts
    Pop-Location

} elseif ($env:build_type -eq "android_lua_tests") {
    Write-Host "Build tests\lua-test"
    Push-Location $env:APPVEYOR_BUILD_FOLDER\tests\lua-tests\project\proj.android\
    # tocheck, release mode failed on "LuaTests:mergeReleaseAssets"
    & ./gradlew assembleDebug -PPROP_BUILD_TYPE=ndk-build --parallel --info
    if ($lastexitcode -ne 0) {throw}
    PushAndroidArtifacts
    Pop-Location

} elseif ($env:build_type -eq "android_cpp_empty_test") {
    Write-Host "Build tests\cpp-empty-test"
    Push-Location $env:APPVEYOR_BUILD_FOLDER\tests\cpp-empty-test\proj.android\
    & ./gradlew assembleRelease
    if ($lastexitcode -ne 0) {throw}
    PushAndroidArtifacts
    Pop-Location

} elseif ($env:build_type -eq "android_cocos_new_test") {
    Write-Host "Create new project cocos_new_test"
    & $python -u tools\cocos2d-console\bin\cocos.py --agreement n new -l cpp -p my.pack.qqqq cocos_new_test
    if ($lastexitcode -ne 0) {throw}

    Write-Host "Build cocos_new_test"
    Push-Location $env:APPVEYOR_BUILD_FOLDER\cocos_new_test\proj.android\
    & ./gradlew assembleRelease -PPROP_BUILD_TYPE=cmake --parallel --info
    if ($lastexitcode -ne 0) {throw}
    PushAndroidArtifacts
    Pop-Location
# TODO: uncomment when fixed
# } elseif ($env:build_type -eq "android_gen_libs") {
#     Write-Host "Build cocos gen-libs"
#     & $python -u tools\cocos2d-console\bin\cocos.py gen-libs -p android -m release --ap android-15 --app-abi armeabi-v7a --agreement n
#     if ($lastexitcode -ne 0) {throw}

} elseif ($env:build_type -eq "windows32_cmake_test") {
    Write-Host "Build tests project by cmake"

    & mkdir $env:APPVEYOR_BUILD_FOLDER\win32-build
    # if ($lastexitcode -ne 0) {throw} # mkdir return no-zero

    Push-Location $env:APPVEYOR_BUILD_FOLDER\win32-build
    & cmake -DCMAKE_BUILD_TYPE=Release ..
    if ($lastexitcode -ne 0) {throw}

    & cmake --build . --config Release
    if ($lastexitcode -ne 0) {throw}

    & 7z a release_win32.7z $env:APPVEYOR_BUILD_FOLDER\win32-build\bin\
    if ($lastexitcode -ne 0) {throw}

    Push-AppveyorArtifact release_win32.7z
    Pop-Location
}
Else {
    # default, windows32_sln_test
    & msbuild $env:APPVEYOR_BUILD_FOLDER\build\cocos2d-win32.sln /t:Build /p:Platform="Win32" /p:Configuration="Release" /m /consoleloggerparameters:"PerformanceSummary;NoSummary"

    if ($lastexitcode -ne 0) {throw}
    & 7z a release_win32.7z $env:APPVEYOR_BUILD_FOLDER\build\Release.win32\
    if ($lastexitcode -ne 0) {throw}

    Push-AppveyorArtifact release_win32.7z
}
