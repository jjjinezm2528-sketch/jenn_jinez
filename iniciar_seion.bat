
@echo off
setlocal EnableExtensions
title ERP Django - USB a PC

REM ======================================================
REM ERP DJANGO :: USB -> PC
REM Detecta automaticamente la letra de la USB.
REM No copia el entorno virtual de otra computadora.
REM ======================================================

set "USB=%~d0\WorkSpace_ERP"
set "PC=C:\Temp_Workspace_ERP"

echo.
echo ======================================================
echo          ERP DJANGO :: USB -^> PC
echo ======================================================
echo USB: %USB%
echo PC:  %PC%
echo.

REM 1. Comprobar que existe el proyecto en la USB
if not exist "%USB%\manage.py" (
    echo [ERROR] No se encontro manage.py en:
    echo %USB%
    echo.
    echo Comprueba que WorkSpace_ERP este en la raiz de la USB.
    pause
    exit /b 1
)

REM 2. Crear la carpeta de trabajo de esta computadora
if not exist "%PC%" mkdir "%PC%"

if not exist "%PC%" (
    echo [ERROR] No se pudo crear la carpeta de trabajo.
    pause
    exit /b 1
)

REM 3. Sincronizar el codigo de la USB a la PC
REM No copiar env_erp: contiene rutas de otra computadora.
REM No borrar archivos de destino que no existan en la USB.

echo Sincronizando proyecto a la PC...

robocopy "%USB%" "%PC%" /E /Z /FFT /R:2 /W:2 ^
 /XD "%USB%\env_erp" "%PC%\env_erp" ^
 /XF "desktop.ini"

set "RC=%ERRORLEVEL%"

if %RC% GEQ 8 (
    echo.
    echo [ERROR] Fallo la sincronizacion del proyecto.
    echo Codigo de Robocopy: %RC%
    pause
    exit /b 1
)

echo [OK] Sincronizacion completada.

REM 4. Crear un entorno virtual propio para esta PC
REM Se utiliza venv, que viene incluido con Python.

if not exist "%PC%\env_erp\Scripts\python.exe" (
    echo.
    echo Creando entorno virtual para esta computadora...

    where py >nul 2>&1
    if not errorlevel 1 (
        py -3.11 -m venv "%PC%\env_erp"
    )

    if not exist "%PC%\env_erp\Scripts\python.exe" (
        where python >nul 2>&1
        if not errorlevel 1 (
            python -m venv "%PC%\env_erp"
        )
    )
)

REM 5. Verificar que el entorno se haya creado correctamente

if not exist "%PC%\env_erp\Scripts\python.exe" (
    echo.
    echo [ERROR] No se pudo crear el entorno virtual.
    echo.
    echo Instala Python 3.11 en esta PC y habilita el comando py,
    echo o comprueba que python funcione desde CMD.
    echo No se continuara con un entorno inexistente.
    pause
    exit /b 1
)

REM 6. Activar el entorno virtual local

call "%PC%\env_erp\Scripts\activate.bat"

if errorlevel 1 (
    echo [ERROR] No se pudo activar el entorno virtual.
    pause
    exit /b 1
)

REM 7. Instalar dependencias si existe requirements.txt

if exist "%PC%\requirements.txt" (
    echo.
    echo Comprobando e instalando dependencias...
    python -m pip install -r "%PC%\requirements.txt"

    if errorlevel 1 (
        echo.
        echo [ERROR] No se pudieron instalar todas las dependencias.
        echo Revisa tu conexion y requirements.txt.
        pause
        exit /b 1
    )
) else (
    echo.
    echo [AVISO] No se encontro requirements.txt.
    echo Si faltan paquetes, sera necesario instalarlos.
)

REM 8. Comprobar Python y Django

echo.
echo ======================================================
echo VERSIONES ACTIVAS
echo ======================================================

python --version
python -m pip --version

echo.
echo Comprobando Django...
python -m django --version

if errorlevel 1 (
    echo.
    echo [AVISO] Django no esta instalado en este entorno.
    echo Comprueba requirements.txt.
) else (
    echo.
    echo Comprobando configuracion del proyecto...
    python "%PC%\manage.py" check
)

REM 9. Entrar en la carpeta del proyecto
cd /d "%PC%"

echo.
echo ======================================================
echo ERP listo en %PC%
echo Entorno virtual: env_erp
echo.
echo Para iniciar Django:
echo python manage.py runserver
echo.
echo Para guardar los cambios en la USB:
echo ejecuta finalizar_sesion.bat al terminar.
echo ======================================================
echo.

cmd /k
