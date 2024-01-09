#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force #Habilitar esta linea en caso de no tener la Instalacion de Nuget.
Install-Module -Name Microsoft.PowerShell.Archive -Force -AllowClobber
Write-Host "Dependencias instaladas con exito."