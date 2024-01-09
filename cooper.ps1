Import-Module WebAdministration
Import-Module IISAdministration

. .\functions-zip-deploy.ps1

# Variable global para almacenar la carpeta de destino
$rutaAccesoFisicaApp = ""
$sitioWebNombre=""
$artefactoNombre=""
$compiladoFinalNombre=""
$poolAplicacionNombre=""
$perfilCD= $null

#14
function Ejecutar-Canalizacion-CD{
	Write-Host "Intentando detener sitio web."
	Detener-Sitio-Web
	Write-Host "Sitio web detenido con exito."
	
	Start-Sleep -Seconds 1

	Write-Host "Intentanto detener Pool Application"
	Detener-IIS
	Write-Host "Pool Application detenido con exito"

	Start-Sleep -Seconds 1
	
	Write-Host "Intentando realizar backup"
	Realizar-Backup
	Write-Host "Backup realizado con exito"

	Start-Sleep -Seconds 1
	
	Write-Host "Intentanto realizar la publicacion de la aplicacion"
	Publicar
	Write-Host "La publicacion se realizo con exito"
	
	Start-Sleep -Seconds 1

	Write-Host "Intentanto iniciar Pool Application"
	Iniciar-IIS
	Write-Host "Pool Application iniciado con exito"
	
	Start-Sleep -Seconds 5

	Write-Host "Intentanto iniciar sitio web"
	Iniciar-Sitio-Web
	Write-Host "Sitio web iniciado con exito"
	
	Start-Sleep -Seconds 2

	Write-Host "Intentando reciclar Pool Application"
	Reclicar-IIS
	Write-Host "Pool Application reciclado con exito"	
	
	Start-Sleep -Seconds 2

	Write-Host "Intentando reiniciar sitio web"
	Reiniciar-Sitio-Web
	Write-Host "Sitio web reiniciado con exito"

}

#13
function Publicar{
	EliminarContenido -rutaDirectorio $global:rutaAccesoFisicaApp
	BuscarYDescomprimirZip -rutaZip $global:artefactoNombre -nombreArchivo $global:compiladoFinalNombre -destinoDescompresion $global:rutaAccesoFisicaApp
}

#12
function Realizar-Backup{
	Comprimir-Carpeta -rutaCarpeta $global:rutaAccesoFisicaApp
}

#11
function Reclicar-IIS{
	#Write-Host "Opcion en desarrollo."
	$sm = Get-IISServerManager
	$sm.ApplicationPools["$global:sitioWebNombre"].Recycle()
	Write-Host "El pool de aplicacion del sitio $global:sitioWebNombre ha sido reciclado exitosamente."
}

#10
function Detener-IIS{
	Stop-WebAppPool -Name $global:poolAplicacionNombre
	#Write-Host "El pool de aplicacion del sitio ha sido detenido exitosamente."
}

#9
function Iniciar-IIS{
	Start-WebAppPool -Name $global:poolAplicacionNombre
	#Write-Host "Pool Application iniciado con exito."
}

#8
function Reiniciar-Sitio-Web{
	Detener-Sitio-Web
	Iniciar-Sitio-Web
	#Restart-WebSite -Name $global:sitioWebNombre
}
#7
function Detener-Sitio-Web{
	Stop-WebSite -Name $global:sitioWebNombre
}
#6
function Iniciar-Sitio-Web{
	Start-WebSite -Name $global:sitioWebNombre
}

#5
function Visualizar-Configuraciones{
	Write-Host "Ruta de acceso fisica de la aplicacion: $global:rutaAccesoFisicaApp"
	Write-Host "Sitio Web (IIS): $global:sitioWebNombre"
	Write-Host "Grupo de aplicacion (IIS): $global:poolAplicacionNombre"
	Write-Host "Artefacto (.zip): $global:artefactoNombre"
	Write-Host "Compilado final (.zip): $global:compiladoFinalNombre"
}

#4
function Seleccionar-Compilado-Final{
	$nombreZipADescomprimir = Read-Host "Ingresa el nombre del compilado final (.zip)"
	$global:compiladoFinalNombre = $nombreZipADescomprimir
}

#3
function Seleccionar-Artefacto{
	# Solicitar la ruta del artefacto zip
	$rutaArchivoZip = Seleccionar-Objetos -tipoExtension 'zip'
	$global:artefactoNombre = $rutaArchivoZip
}

#2
function Listar-SitiosWeb {
    # Obtener la lista de sitios web en IIS
    $sitiosWeb = Get-Website

    # Mostrar la lista de sitios web al usuario
    Write-Host "Sitios web en IIS:"
    foreach ($sitio in $sitiosWeb) {
        Write-Host "$($sitio.Id). $($sitio.Name)"
    }

    # Permitir al usuario seleccionar un sitio web
    do {
        $idSitioSeleccionado = Read-Host "Seleccione el ID del sitio web que desea asignar a la variable global (o presione 'Enter' para cancelar)"
    } while ($idSitioSeleccionado -ne '' -and ($sitiosWeb | Where-Object { $_.Id -eq $idSitioSeleccionado }) -eq $null)

    # Verificar si se seleccionó un sitio web
    if ($idSitioSeleccionado -ne '') {
        # Asignar el sitio web seleccionado a una variable global
        $global:SitioWebSeleccionado = $sitiosWeb | Where-Object { $_.Id -eq $idSitioSeleccionado }
		$global:sitioWebNombre = $($SitioWebSeleccionado.Name)
		Obtener-PoolAplicacionPorSitio -nombreSitio $($SitioWebSeleccionado.Name)
    } else {
        Write-Host "No se seleccionó ningún sitio web."
    }
}

function Obtener-PoolAplicacionPorSitio {
    param (
        [string]$nombreSitio
    )

    # Obtener información del sitio web
    $sitioWeb = Get-WebSite -Name $nombreSitio -ErrorAction SilentlyContinue

    if ($sitioWeb -eq $null) {
        Write-Host "ERROR: No se encontró el sitio web con el nombre '$nombreSitio'."
        return
    }

	Write-Host "ID del Sitio Web: $($sitioWeb.Id)"
    Write-Host "Nombre del Sitio Web: $($sitioWeb.Name)"
    Write-Host "Estado del Sitio Web: $($sitioWeb.State)"
    Write-Host "Bindings: $($sitioWeb.Bindings.Collection.BindingInformation)"
   
	$sitio = Get-IISSite -Name $global:sitioWebNombre
	if ($sitio -eq $null) {
		Write-Host "El sitio '$nombreSitio' no fue encontrado."
	} else {
		# Obtener el nombre del Application Pool asociado al sitio
		$applicationPool = $sitio.Applications[0].ApplicationPoolName
		$global:poolAplicacionNombre = $applicationPool
		# Imprimir el nombre del Application Pool
		Write-Host "Application Pool: $applicationPool"
	}
}

#1
function Configurar-Ruta-Acceso-App {
    $ruta = Read-Host "Ingrese la ruta de acceso fisica de la aplicacion"
	
	if($ruta -eq ''){
		Write-Host "La ruta esta vacia o no es valida."
		Read-Host "Presione Enter para continuar..."
		return;
	}

    if (Test-Path $ruta -PathType Container) {
        Write-Host "Carpeta destino establecida correctamente: $ruta"
        # Guardar la ruta en la variable global
        $global:rutaAccesoFisicaApp = $ruta
    } else {
        Write-Host "La carpeta destino no existe."
        # Restablecer la variable global en caso de error
        $global:rutaAccesoFisicaApp = ""
    }

    Read-Host "Presione Enter para continuar..."
}

# 0
function Guardar-Configuraciones {
	$nombreArchivoCompleto = ""
    do {
		if($global:perfilCD -ne $null){
			$nombreArchivo = [System.IO.Path]::GetFileName($global:perfilCD)
			$nombreArchivoCompleto = $nombreArchivo
		}else{
			$nombreArchivo = Read-Host "Ingrese el nombre del archivo para guardar el objeto (No agregue extension al objeto. Si el objeto existe sera reemplezado)"
			$nombreArchivoCompleto = $nombreArchivo + ".cd"
		}
		
        if ($nombreArchivo -eq "") {
            Write-Host "ERROR: El nombre del archivo no puede estar vacío."
        } elseif ($nombreArchivo -notmatch "^[\w\-.]+$") {
            Write-Host "ERROR: El nombre del archivo contiene caracteres no permitidos. Solo se permiten letras, números, guiones bajos, guiones y puntos."
        }
    } while ($nombreArchivo -eq "" -or $nombreArchivo -notmatch "^[\w\-.]+$")

    $contenido = @(
        "rutaAccesoFisicaApp=$global:rutaAccesoFisicaApp",
		"sitioWebNombre=$global:sitioWebNombre",
		"poolAplicacionNombre=$global:poolAplicacionNombre",
		"artefactoNombre=$global:artefactoNombre",
		"compiladoFinalNombre=$global:compiladoFinalNombre"
    )

    # Guardar el contenido en el archivo
    $contenido | Out-File -FilePath $nombreArchivoCompleto

    Write-Host "Perfil guardado correctamente en '$nombreArchivoCompleto'"
}

# utils
function Seleccionar-Objetos {
    param (
        [string]$tipoExtension
    )

    # Directorio donde se encuentran los objetos
    $directorioPerfiles = Get-Location

    # Verificar si existen archivos con la extensión especificada
    $archivosPerfiles = Get-ChildItem -Path $directorioPerfiles -Filter "*.$tipoExtension"

    if ($archivosPerfiles.Count -gt 0) {
        Write-Host "Objetos encontrados con extensión . $tipoExtension"
        
        # Mostrar la lista de archivos con la extensión especificada
        $i = 1
        foreach ($archivo in $archivosPerfiles) {
            Write-Host "$i. $($archivo.Name)"
            $i++
        }

        # Permitir al usuario seleccionar un objeto
        do {
            $opcionPerfil = Read-Host "Seleccione un objeto (1-$($archivosPerfiles.Count)) o presione 'Enter' para continuar sin seleccionar."
        } while ($opcionPerfil -ne '' -and ($opcionPerfil -lt 1 -or $opcionPerfil -gt $archivosPerfiles.Count))

        if ($opcionPerfil -ne '') {
            $perfilCD = $archivosPerfiles[$opcionPerfil - 1]
            Write-Host "Ha seleccionado el objeto: $($perfilCD.Name)"
            #Cargar-Perfil -archivo $perfilCD.FullName
            return $perfilCD.FullName
        } else {
            Write-Host "Continuando sin seleccionar un objeto."
        }
    } else {
        Write-Host "No se encontraron objetos con la extensión .$tipoExtension."
		Read-Host "Presione una tecla para continuar..."
    }

    return $null
}


function Mostrar-TituloPerfil{
	if($global:perfilCD -ne $null){
		$nombreArchivo = [System.IO.Path]::GetFileName($global:perfilCD)
		Write-Host "Perfil Seleccionado: $nombreArchivo"
	}
}

function EliminarContenido {
    param (
        [string]$rutaDirectorio
    )

    # Verificar si la ruta del directorio es válida
    if (Test-Path -Path $rutaDirectorio -PathType Container) {
        # Eliminar el contenido de la carpeta forzadamente
        Remove-Item -Path "$rutaDirectorio\*" -Force -Recurse
        Write-Host "Contenido de la carpeta eliminado correctamente."
    } else {
        Write-Host "La ruta del directorio no es válida."
    }
}


# Función para cargar el perfil desde un archivo
function Cargar-Perfil {
    param (
		[string]$archivo
    )
	
	# Verificar si el archivo existe
    if (Test-Path $archivo -PathType Leaf) {
        # Leer el contenido del archivo
        $contenido = Get-Content -Path $archivo
		
        # Iterar sobre las líneas del archivo y actualizar las variables
        foreach ($linea in $contenido) {
            $nombreVariable, $valorVariable = $linea -split '=', 2	
            Set-Variable -Name $nombreVariable -Value $valorVariable -Scope global -Force
        }

        Write-Host "Perfil cargado correctamente desde '$archivo'"
		$global:perfilCD = $archivo
    } else {
        Write-Host "ERROR: El archivo '$archivo' no existe."
    }
}

function Mostrar-Menu {
    Clear-Host
	Write-Host "*********** MENU PRINCIPAL ***********"
    Mostrar-TituloPerfil
	Write-Host ""
	Write-Host ">> Configuraciones"
	Write-Host "1. Configurar ruta de acceso fisica de la aplicacion. $global:rutaAccesoFisicaApp"
	Write-Host "2. Seleccionar Sitio Web. $global:sitioWebNombre"
	Write-Host "3. Seleccionar Artefacto (.zip). $global:artefactoNombre"
	Write-Host "4. Configurar nombre del compilado final (.zip). $global:compiladoFinalNombre"
	Write-Host "5. Visualizar Configuraciones."
	Write-Host ""
	Write-Host ">> Ejecuciones del IIS (Control Manual)"
	Write-Host "6. Iniciar Sitio Web (IIS)"
	Write-Host "7. Detener Sitio Web (IIS)"
	Write-Host "8. Reiniciar Sitio Web (IIS)"
	Write-Host "9. Iniciar Pool Application (IIS)"
	Write-Host "10. Detener Pool Application (IIS)"
	Write-Host "11. Reciclar Pool Application (IIS)"
	Write-Host ""
	Write-Host ">> Backup y Publicacion(Control Manual)"
	Write-Host "12. Realizar un Backup de la aplicacion."
	Write-Host "13. Publicar aplicacion en caliente."
	Write-Host ""
	Write-Host ">> Entrega Continua (CD)"
    Write-Host "14. Ejecutar Canalización de Entrega."
	Write-Host ""
    Write-Host "99. Salir"
}

$fullnamefile = Seleccionar-Objetos -tipoExtension 'cd'
Cargar-Perfil -archivo $fullnamefile 
do {
	
    Mostrar-Menu
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion) {
        1 {
            Configurar-Ruta-Acceso-App
        }
		2{
			Listar-SitiosWeb
		}
        
        3 {			
			Seleccionar-Artefacto
        }
        4 {
			Seleccionar-Compilado-Final
        }
		5{
			Visualizar-Configuraciones
		}
		6{
			Iniciar-Sitio-Web
		}
		7{
			Detener-Sitio-Web
		}
		8{
			Reiniciar-Sitio-Web
		}
		9{
			Iniciar-IIS
		}
		10{
			Detener-IIS
		}
		11{
			Reclicar-IIS
		}
		12{
			Realizar-Backup
		}
		13{
			Publicar
		}
		14{
			Ejecutar-Canalizacion-CD
		}
		0 {
            Guardar-Configuraciones
        }
		99{
			#Write-Host "Saliendo del programa..."
		}
        default {
            Write-Host "Opcion no valida. Intentelo de nuevo."
        }
		
    }
	Read-Host "Presione Enter para continuar..."
} while ($opcion -ne 99)
