
$path = (Resolve-Path '.').Path
if ($env:PSModulePath -like "*$path*") {
    $env:PSModulePath = $env:PSModulePath -replace ";$path", ""
}