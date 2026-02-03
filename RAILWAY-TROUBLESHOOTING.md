# 🔧 SOLUCIÓN: ERROR DE BUILD EN RAILWAY

## ❌ ERROR QUE TIENES

```
Deployment failed during the build process
Error creating build plan with Railpack
```

## ✅ SOLUCIÓN COMPLETA

### **PASO 1: Añadir archivos de configuración**

Descarga estos nuevos archivos y añádelos a tu repositorio:

```
cerrajerosya-backend/
├── nixpacks.toml          ← NUEVO (añadir)
├── railway.json           ← NUEVO (añadir)
├── Procfile               ← NUEVO (añadir)
├── package.json           ← ACTUALIZAR (nueva versión)
├── .gitignore
├── server.js
├── README.md
└── src/
    └── ...
```

### **PASO 2: Actualizar repositorio en GitHub**

```bash
# En tu carpeta del proyecto
cd cerrajerosya-backend

# Copiar los archivos nuevos:
# - nixpacks.toml
# - railway.json
# - Procfile
# - package.json (actualizado)

# Añadir archivos
git add .

# Commit
git commit -m "Add Railway configuration files"

# Push
git push origin main
```

### **PASO 3: Verificar estructura del repositorio**

Tu repositorio en GitHub DEBE tener:

```
✓ package.json (en la raíz)
✓ server.js (en la raíz)
✓ nixpacks.toml (en la raíz)
✓ railway.json (en la raíz)
✓ Procfile (en la raíz)
✓ src/ (carpeta con todo el código)
✓ .gitignore
```

### **PASO 4: Re-deploy en Railway**

Una vez los archivos estén en GitHub:

**Opción A: Trigger automático**
- Railway detectará el push y hará deploy automáticamente
- Espera 2-3 minutos

**Opción B: Deploy manual**
1. Ve a tu proyecto en Railway
2. Click en **"Deployments"**
3. Click en **"Deploy"** (botón arriba derecha)
4. Selecciona **"Redeploy"**

---

## 🔍 VERIFICACIÓN PASO A PASO

### **1. Verificar package.json**

Tu `package.json` DEBE tener:

```json
{
  "name": "cerrajerosya-backend",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  },
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "express": "^4.18.2",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    ...
  }
}
```

### **2. Verificar server.js**

El archivo `server.js` debe:
- Estar en la **raíz** del proyecto
- Empezar con `require('dotenv').config();`
- Tener `const app = express();`
- Terminar con `app.listen(PORT, ...)`

### **3. Verificar variables de entorno en Railway**

1. Ve a Railway → Tu proyecto → **Variables**
2. Verifica que están configuradas:

```env
NODE_ENV=production
PORT=3000
SUPABASE_URL=https://obghpxmykrysjpjnmksf.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_KEY=eyJhbGci...
```

---

## 🚨 ERRORES COMUNES Y SOLUCIONES

### **Error: "Cannot find module"**

**Causa:** Falta algún archivo o está mal la ruta.

**Solución:**
```bash
# Verificar que todos los archivos existen
ls -la
ls -la src/
ls -la src/config/
ls -la src/controllers/
```

### **Error: "Missing dependencies"**

**Causa:** `package.json` no tiene todas las dependencias.

**Solución:** Usa el `package.json` actualizado que te acabo de dar.

### **Error: "Module not found: @supabase/supabase-js"**

**Causa:** Railway no instaló las dependencias.

**Solución:** Añade `railway.json` con `buildCommand: "npm install"`.

---

## 📋 CHECKLIST ANTES DE RE-DEPLOY

- [ ] `package.json` tiene `"start": "node server.js"`
- [ ] `package.json` tiene `engines` con node >= 18
- [ ] `server.js` está en la raíz
- [ ] `nixpacks.toml` añadido
- [ ] `railway.json` añadido
- [ ] `Procfile` añadido
- [ ] Todo subido a GitHub (`git push`)
- [ ] Variables de entorno configuradas en Railway

---

## 🎯 ALTERNATIVA: USAR RENDER INSTEAD

Si Railway sigue dando problemas, puedes usar Render (más estable):

### **Deploy en Render:**

1. Ve a https://render.com
2. **New +** → **Web Service**
3. Conecta con GitHub
4. Selecciona tu repositorio
5. Configura:
   - **Name:** cerrajerosya-backend
   - **Environment:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `node server.js`
   - **Instance Type:** Free

6. Añade variables de entorno (las mismas que Railway)
7. Click **Create Web Service**

Render es más estable pero un poco más lento en el tier gratuito.

---

## ✅ DESPUÉS DE SOLUCIONAR

Una vez el deploy sea exitoso, deberías ver en Railway:

```
✓ Build successful
✓ Deploy successful
✓ Service running
```

Luego podrás acceder a:
```
https://tu-url.railway.app/health
```

Y ver:
```json
{
  "status": "ok",
  "timestamp": "2026-02-02T...",
  "environment": "production"
}
```

---

## 🆘 SI NADA FUNCIONA

**Opción 1:** Comparte los logs completos del error de Railway

**Opción 2:** Verifica que tu repositorio GitHub tiene exactamente esta estructura:

```
cerrajerosya-backend/
├── .gitignore
├── nixpacks.toml
├── package.json
├── Procfile
├── railway.json
├── README.md
├── server.js
└── src/
    ├── config/
    │   └── supabase.js
    ├── controllers/
    │   └── leads.controller.js
    ├── routes/
    │   └── leads.routes.js
    ├── services/
    │   └── assignment.engine.js
    └── utils/
        ├── errors.js
        └── logger.js
```

**Opción 3:** Crea un repositorio nuevo desde cero con solo los archivos esenciales.

---

**¿Necesitas más ayuda?** Comparte el error exacto de Railway y te ayudo a solucionarlo. 🚀
