function BuscarYDescomprimirZip {
    param (
        [string]$rutaZip,
        [string]$nombreArchivo,
        [string]$destinoDescompresion = [System.IO.Path]::GetTempPath()
    )

    # Comprobar si la ruta del archivo ZIP proporcionada existe
    if (Test-Path $rutaZip) {
        # Descomprimir el archivo ZIP en una carpeta temporal
        $tempFolder = Join-Path $destinoDescompresion "TempExtractedFolder"

        Expand-Archive -Path $rutaZip -DestinationPath $tempFolder -Force

        # Buscar el archivo dentro de la carpeta temporal y subcarpetas
        $archivoBuscado = Get-ChildItem -Path $tempFolder -Recurse -Filter $nombreArchivo -File

        # Mostrar la ruta del archivo si se encuentra
        if ($archivoBuscado) {
            Write-Host "El archivo '$nombreArchivo' se encontró en: $($archivoBuscado.FullName)"

            # Descomprimir el archivo ZIP encontrado en el destino especificado
            $destinoDescompresionFinal = $destinoDescompresion #Join-Path $destinoDescompresion "Descomprimido"

            Expand-Archive -Path $archivoBuscado.FullName -DestinationPath $destinoDescompresionFinal -Force

            Write-Host "El archivo '$nombreArchivo' se descomprimió en: $destinoDescompresionFinal"
        } else {
            Write-Host "El archivo '$nombreArchivo' no se encontró en el archivo ZIP."
        }

        # Limpiar la carpeta temporal después de la búsqueda
        Remove-Item -Path $tempFolder -Recurse -Force
    } else {
        Write-Host "La ruta del archivo ZIP proporcionada no es válida."
    }
}

function Comprimir-Carpeta {
    param (
        [string]$rutaCarpeta
    )

    # Verificar si la carpeta existe
    if (-not (Test-Path $rutaCarpeta -PathType Container)) {
        Write-Host "ERROR: La carpeta '$rutaCarpeta' no existe."
        return
    }

    # Obtener la fecha actual en formato YYYY-MM-DD
    $fechaActual = Get-Date -Format "yyyy-MM-dd"

    # Construir el nombre del archivo ZIP con la convención especificada
    $version = 1
    $nombreArchivoZIP = "{0} BK {1} v{2}.zip" -f (Split-Path $rutaCarpeta -Leaf), $fechaActual, $version

    # Verificar si el archivo ZIP ya existe y ajustar la versión si es necesario
    while (Test-Path $nombreArchivoZIP) {
        $version++
        $nombreArchivoZIP = "{0} BK {1} v{2}.zip" -f (Split-Path $rutaCarpeta -Leaf), $fechaActual, $version
    }

    # Comprimir la carpeta
    Compress-Archive -Path $rutaCarpeta -DestinationPath $nombreArchivoZIP

    Write-Host "Carpeta comprimida exitosamente. Archivo ZIP creado: $nombreArchivoZIP"
}