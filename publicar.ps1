<#
.SYNOPSIS
  Publica o actualiza el portafolio en GitHub Pages.

.DESCRIPTION
  1. Inicializa el repositorio git si no existe.
  2. Crea el repositorio en GitHub si no existe (publico).
  3. Hace commit de todos los cambios y push a la rama main.
  4. Activa GitHub Pages (rama main, carpeta raiz) si no esta activo.
  5. Espera a que el despliegue termine y muestra la URL.

.EXAMPLE
  .\publicar.ps1
  .\publicar.ps1 -Mensaje "Actualizo seccion de proyectos"
  .\publicar.ps1 -Repo "otro-nombre" -NoEsperar
#>
param(
  [string]$Mensaje = "",
  [string]$Repo = "portafolio",
  [string]$Rama = "main",
  [switch]$NoEsperar
)

$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $PSScriptRoot

function Paso($texto) { Write-Host "`n==> $texto" -ForegroundColor Cyan }
function Falla($texto) { Write-Host "ERROR: $texto" -ForegroundColor Red; exit 1 }
function Ok($texto) { Write-Host "    $texto" -ForegroundColor Green }

# --- Requisitos -------------------------------------------------------------
Paso "Verificando herramientas"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Falla "git no esta instalado." }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Falla "GitHub CLI (gh) no esta instalado: winget install GitHub.cli" }

# Autenticacion: usa la sesion de gh; si no hay, reutiliza la credencial guardada de git.
gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
  $env:GIT_TERMINAL_PROMPT = "0"
  # PowerShell 5.1 agrega BOM al enviar texto a git y este lo rechaza;
  # por eso la consulta se escribe a un archivo temporal y se redirige con cmd.
  $tmp = [System.IO.Path]::GetTempFileName()
  [System.IO.File]::WriteAllBytes($tmp, [System.Text.Encoding]::ASCII.GetBytes("protocol=https`nhost=github.com`n`n"))
  $cred = cmd /c "git credential fill < `"$tmp`"" 2>$null
  Remove-Item -LiteralPath $tmp -Force
  $linea = $cred | Where-Object { $_ -like "password=*" } | Select-Object -First 1
  $token = if ($linea) { ([string]$linea).Substring(9).Trim() } else { "" }
  if (-not $token) { Falla "No hay sesion de GitHub. Ejecuta: gh auth login" }
  $env:GH_TOKEN = $token
}
$usuario = gh api user --jq .login 2>$null
if ($LASTEXITCODE -ne 0 -or -not $usuario) { Falla "No se pudo autenticar con GitHub. Ejecuta: gh auth login" }
Ok "Autenticado como $usuario"
$slug = "$usuario/$Repo"

# --- Repositorio local ------------------------------------------------------
if (-not (Test-Path ".git")) {
  Paso "Inicializando repositorio local"
  git init -b $Rama | Out-Null
}

# --- Repositorio remoto -----------------------------------------------------
Paso "Verificando repositorio remoto $slug"
gh api "repos/$slug" *> $null
if ($LASTEXITCODE -ne 0) {
  gh repo create $slug --public --description "Portafolio personal" | Out-Null
  if ($LASTEXITCODE -ne 0) { Falla "No se pudo crear el repositorio $slug" }
  Ok "Repositorio creado"
} else {
  Ok "El repositorio ya existe"
}
$urlRemoto = "https://github.com/$slug.git"
git remote get-url origin *> $null
if ($LASTEXITCODE -ne 0) { git remote add origin $urlRemoto } else { git remote set-url origin $urlRemoto }

# --- Commit y push ----------------------------------------------------------
Paso "Guardando cambios"
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  if (-not $Mensaje) { $Mensaje = "Actualizacion del portafolio $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
  git commit -m $Mensaje | Out-Null
  if ($LASTEXITCODE -ne 0) { Falla "Fallo el commit" }
  Ok "Commit: $Mensaje"
} else {
  Ok "No hay cambios nuevos para guardar"
}

Paso "Subiendo a GitHub"
git branch -M $Rama
git push -u origin $Rama
if ($LASTEXITCODE -ne 0) { Falla "Fallo el push" }

# --- GitHub Pages -----------------------------------------------------------
Paso "Configurando GitHub Pages"
gh api "repos/$slug/pages" *> $null
if ($LASTEXITCODE -ne 0) {
  gh api -X POST "repos/$slug/pages" -f "source[branch]=$Rama" -f "source[path]=/" | Out-Null
  if ($LASTEXITCODE -ne 0) { Falla "No se pudo activar GitHub Pages" }
  Ok "GitHub Pages activado"
} else {
  Ok "GitHub Pages ya estaba activo"
}

$url = "https://$($usuario.ToLower()).github.io/$Repo/"
if ($Repo -ieq "$usuario.github.io") { $url = "https://$($usuario.ToLower()).github.io/" }

# --- Esperar despliegue -----------------------------------------------------
if (-not $NoEsperar) {
  Paso "Esperando el despliegue (puede tardar 1-2 minutos)"
  $sha = git rev-parse HEAD
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 6
    $build = gh api "repos/$slug/pages/builds/latest" 2>$null | ConvertFrom-Json
    if (-not $build) { Write-Host "    ...pendiente"; continue }
    if ($build.status -eq "built" -and $build.commit -eq $sha) { Ok "Despliegue completado"; break }
    if ($build.status -eq "errored") { Falla "El despliegue fallo. Revisa: https://github.com/$slug/actions" }
    Write-Host "    ...$($build.status)"
  }
}

Write-Host "`nPortafolio publicado en: $url" -ForegroundColor Green
