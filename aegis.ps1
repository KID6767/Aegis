# ================================
# Aegis Installer (PowerShell)
# ================================

param(
    [string]$Base64File = ".\aegis.b64",
    [string]$ZipFile = ".\Aegis-1.0.1.zip",
    [string]$TargetDir = ".\Aegis"
)

function Log($msg) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "$time  $msg"
}

Write-Host "== Aegis Installer ==" -ForegroundColor Cyan

try {
    if (!(Test-Path $Base64File)) {
        throw "Nie znaleziono pliku $Base64File"
    }

    Log "Dekoduję $Base64File do $ZipFile ..."
    certutil -f -decode $Base64File $ZipFile | Out-Null

    if (!(Test-Path $ZipFile)) {
        throw "Dekodowanie nie powiodło się – brak pliku ZIP"
    }

    Log "Rozpakowuję $ZipFile do $TargetDir ..."
    if (Test-Path $TargetDir) {
        Remove-Item -Recurse -Force $TargetDir
    }
    Expand-Archive -LiteralPath $ZipFile -DestinationPath $TargetDir -Force

    Log "Instalacja zakończona ✅"
}
catch {
    Write-Host "BŁĄD: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
