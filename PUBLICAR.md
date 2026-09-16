# Publicación del portafolio en GitHub Pages

Este documento explica cómo se publicó el portafolio y cómo actualizarlo.

- **Sitio publicado:** https://jdiego9708.github.io/portafolio/
- **Repositorio:** https://github.com/jdiego9708/portafolio
- **Carpeta local:** `E:\Personal\Portafolio`

---

## Actualizar el portafolio (uso diario)

1. Edita `index.html`, cambia `retrato.jpg` o agrega archivos en esta carpeta.
2. Publica con **una** de estas opciones:
   - **Doble clic** en `publicar.cmd`, o
   - Desde PowerShell, dentro de la carpeta:
     ```powershell
     .\publicar.ps1
     .\publicar.ps1 -Mensaje "Agrego proyecto nuevo"
     ```
3. El script muestra la URL cuando termina. Los cambios pueden tardar 1–2 minutos
   en verse; si no aparecen, recarga con `Ctrl + F5`.

### Opciones del script

| Parámetro     | Por defecto   | Descripción                                          |
|---------------|---------------|------------------------------------------------------|
| `-Mensaje`    | fecha y hora  | Mensaje del commit                                   |
| `-Repo`       | `portafolio`  | Nombre del repositorio en GitHub                     |
| `-Rama`       | `main`        | Rama que publica GitHub Pages                        |
| `-NoEsperar`  | —             | No espera a que termine el despliegue                |

---

## Qué hace `publicar.ps1`, paso a paso

1. **Verifica herramientas:** `git` y GitHub CLI (`gh`).
2. **Autentica:** usa la sesión de `gh`; si no hay, reutiliza la credencial de GitHub
   guardada por Git Credential Manager (la misma que usa `git push`).
3. **Repositorio local:** si la carpeta no tiene `.git`, ejecuta `git init -b main`.
4. **Repositorio remoto:** si `usuario/portafolio` no existe en GitHub, lo crea como
   público (GitHub Pages gratuito requiere repositorio público) y configura `origin`.
5. **Commit:** `git add -A` y commit solo si hay cambios.
6. **Push:** `git push -u origin main`.
7. **GitHub Pages:** si no está activo, lo activa vía API
   (`POST /repos/{usuario}/{repo}/pages` con origen rama `main`, carpeta `/`).
8. **Espera el despliegue:** consulta `pages/builds/latest` hasta que el commit
   actual quede en estado `built`, y muestra la URL.

El script es idempotente: se puede ejecutar cuantas veces se quiera; lo que ya
existe no se vuelve a crear.

---

## Archivos de configuración

| Archivo        | Propósito                                                          |
|----------------|--------------------------------------------------------------------|
| `index.html`   | Página principal del portafolio (GitHub Pages la sirve en la raíz) |
| `retrato.jpg`  | Imagen usada por la página                                         |
| `.nojekyll`    | Indica a GitHub Pages que sirva los archivos tal cual, sin Jekyll  |
| `.gitignore`   | Excluye respaldos locales (`*.backup-*.html`) de la publicación    |
| `publicar.ps1` | Script de publicación/actualización                                |
| `publicar.cmd` | Acceso directo de doble clic al script                             |
| `PUBLICAR.md`  | Este documento                                                     |

> Todo lo que esté en el repositorio es público, incluidos estos documentos.
> No guardes aquí información privada.

---

## Proceso manual equivalente (sin script)

```powershell
cd E:\Personal\Portafolio
git init -b main
gh repo create jdiego9708/portafolio --public
git remote add origin https://github.com/jdiego9708/portafolio.git
git add -A
git commit -m "Publicación inicial del portafolio"
git push -u origin main
gh api -X POST repos/jdiego9708/portafolio/pages -f "source[branch]=main" -f "source[path]=/"
```

O desde la web: **Repositorio → Settings → Pages → Build and deployment →
Source: Deploy from a branch → Branch: `main` / `(root)` → Save**.

---

## Solución de problemas

| Problema                                 | Solución                                                                 |
|------------------------------------------|--------------------------------------------------------------------------|
| `No hay sesion de GitHub`                | Ejecuta `gh auth login` y vuelve a correr el script                      |
| `gh` no está instalado                   | `winget install GitHub.cli`                                              |
| PowerShell bloquea el script             | Usa `publicar.cmd` o `powershell -ExecutionPolicy Bypass -File publicar.ps1` |
| El sitio muestra la versión anterior     | Espera 1–2 minutos y recarga con `Ctrl + F5`                             |
| Error 404 en la URL                      | Revisa Settings → Pages en el repositorio; el primer despliegue tarda más |
| Imagen no carga                          | Las rutas distinguen mayúsculas: `retrato.jpg` ≠ `Retrato.JPG`           |

### Opcional: URL sin `/portafolio/`

Para publicar en `https://jdiego9708.github.io/` directamente, usa un repositorio
llamado exactamente `jdiego9708.github.io`:

```powershell
.\publicar.ps1 -Repo "jdiego9708.github.io"
```
