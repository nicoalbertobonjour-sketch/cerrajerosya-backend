# 🚀 GUÍA RÁPIDA DE DESPLIEGUE
## cerrajerosya.es - De 0 a Producción en 30 minutos

---

## ✅ LO QUE YA TIENES LISTO

1. ✅ **Supabase configurado**
   - URL: https://obghpxmykrysjpjnmksf.supabase.co
   - Credenciales: Ya en el archivo `.env`

2. ✅ **Backend completo**
   - Todos los archivos creados
   - Motor de asignación funcionando
   - API REST completa

3. ✅ **Frontend existente**
   - Landing page
   - Dashboard de gestión

---

## 📋 PASOS PARA DESPLEGAR

### **PASO 1: EJECUTAR SQL EN SUPABASE** (5 minutos)

1. Ve a: https://app.supabase.com/project/obghpxmykrysjpjnmksf
2. Click en **"SQL Editor"** (menú izquierdo)
3. Click en **"New query"**
4. Abre el archivo **`supabase-schema.sql`** que te di
5. Copia TODO el contenido y pégalo
6. Click en **"Run"** (o Ctrl + Enter)
7. Espera ~10 segundos
8. Deberías ver: ✅ **"Success. No rows returned"**

**Si hay error:** Ejecuta **`supabase-quickfix.sql`** en su lugar.

---

### **PASO 2: CREAR REPOSITORIO GITHUB** (5 minutos)

1. Ve a: https://github.com/new
2. Nombre del repositorio: `cerrajerosya-backend`
3. Privado o Público (tu eliges)
4. **NO añadas README, .gitignore ni licencia**
5. Click en **"Create repository"**

GitHub te mostrará comandos. **Cópialos** (los usarás en el paso 3).

---

### **PASO 3: SUBIR EL CÓDIGO A GITHUB** (5 minutos)

En tu ordenador, crea una carpeta y organiza los archivos así:

```
cerrajerosya-backend/
├── .env
├── .gitignore
├── package.json
├── server.js
├── src/
│   ├── config/
│   │   └── supabase.js
│   ├── controllers/
│   │   └── leads.controller.js
│   ├── services/
│   │   └── assignment.engine.js
│   ├── routes/
│   │   └── leads.routes.js
│   └── utils/
│       ├── logger.js
│       └── errors.js
└── README.md
```

**IMPORTANTE:** Todos los archivos que tienen nombres como:
- `src-config-supabase.js` → renombrar a `src/config/supabase.js`
- `src-controllers-leads.controller.js` → renombrar a `src/controllers/leads.controller.js`
- etc.

Luego ejecuta:

```bash
cd cerrajerosya-backend
git init
git add .
git commit -m "Initial backend setup"
git remote add origin https://github.com/TU_USUARIO/cerrajerosya-backend.git
git push -u origin main
```

---

### **PASO 4: DESPLEGAR EN RAILWAY** (10 minutos)

1. Ve a: https://railway.app
2. Login con GitHub
3. Click en **"New Project"**
4. Click en **"Deploy from GitHub repo"**
5. Autoriza Railway si te lo pide
6. Selecciona **`cerrajerosya-backend`**
7. Railway detectará Node.js automáticamente
8. Click en **"Deploy Now"**

**Espera 2-3 minutos mientras se construye...**

---

### **PASO 5: CONFIGURAR VARIABLES DE ENTORNO** (3 minutos)

1. En Railway, click en tu proyecto
2. Click en la pestaña **"Variables"**
3. Click en **"RAW Editor"** (arriba a la derecha)
4. **Borra todo** lo que haya ahí
5. Abre tu archivo **`.env`** local
6. **Copia TODO el contenido** y pégalo en Railway
7. Click en **"Update Variables"**

Railway reiniciará automáticamente.

---

### **PASO 6: OBTENER LA URL DE TU BACKEND** (1 minuto)

1. En Railway, ve a la pestaña **"Settings"**
2. Baja hasta **"Networking"**
3. Click en **"Generate Domain"**
4. Railway te dará una URL como:
   ```
   https://cerrajerosya-backend-production.up.railway.app
   ```
5. **COPIA ESTA URL** (la necesitarás para el frontend)

---

### **PASO 7: VERIFICAR QUE FUNCIONA** (2 minutos)

1. Abre en tu navegador:
   ```
   https://TU-URL.railway.app/health
   ```

2. Deberías ver:
   ```json
   {
     "status": "ok",
     "timestamp": "2026-02-02T...",
     "environment": "production",
     "version": "1.0.0"
   }
   ```

3. Si ves esto: **¡BACKEND FUNCIONANDO!** ✅

---

### **PASO 8: PROBAR CREAR UN LEAD** (2 minutos)

Usa este comando (reemplaza con tu URL):

```bash
curl -X POST https://TU-URL.railway.app/api/leads \
  -H "Content-Type: application/json" \
  -d '{
    "client_phone": "+34612345678",
    "city": "Madrid",
    "address": "Calle Gran Vía 28",
    "category": "Cerrajería",
    "urgency_level": 4,
    "price": 25.00
  }'
```

Deberías ver:
```json
{
  "success": true,
  "lead": {
    "id": "...",
    "status": "pending",
    "price": 25,
    ...
  }
}
```

---

### **PASO 9: VERIFICAR EN SUPABASE** (1 minuto)

1. Ve a Supabase → **Table Editor**
2. Abre la tabla **`leads`**
3. Deberías ver el lead que acabas de crear

**¡FUNCIONA!** 🎉

---

## 🎯 SIGUIENTE PASO: CONECTAR FRONTEND

Ahora que el backend está funcionando, necesitas actualizar tu frontend.

### En tu `cerrajerosya-landing.html`:

Busca donde dice:

```javascript
// const API_URL = 'http://localhost:3000/api';
```

Y cámbialo por:

```javascript
const API_URL = 'https://TU-URL.railway.app/api';
```

### Actualizar función de envío de leads:

```javascript
async function submitLead(event) {
  event.preventDefault();
  
  const formData = {
    client_phone: document.getElementById('lead-phone').value,
    city: document.getElementById('lead-city').value,
    address: document.getElementById('lead-address').value,
    category: document.getElementById('lead-service').value,
    description: document.getElementById('lead-description').value,
    urgency_level: parseInt(document.querySelector('input[name="urgency"]:checked').value),
    source: 'landing',
    price: 25.00
  };
  
  try {
    const response = await fetch(`${API_URL}/leads`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    });
    
    const data = await response.json();
    
    if (data.success) {
      alert('¡Lead creado correctamente!');
      closeLeadForm();
    }
  } catch (error) {
    console.error('Error:', error);
    alert('Error al enviar el formulario');
  }
}
```

---

## ✅ CHECKLIST FINAL

- [ ] SQL ejecutado en Supabase sin errores
- [ ] Código subido a GitHub
- [ ] Backend desplegado en Railway
- [ ] Variables de entorno configuradas
- [ ] URL de Railway generada
- [ ] Health check responde OK
- [ ] Test de crear lead exitoso
- [ ] Lead visible en Supabase
- [ ] Frontend actualizado con URL del backend

---

## 🆘 TROUBLESHOOTING

### "Application failed to respond"
- Revisa los logs en Railway → Deployments → Tu deployment → Logs
- Verifica que todas las variables de entorno están configuradas

### "CORS policy blocked"
- Añade tu dominio frontend a `CORS_ORIGIN` en Railway

### "Supabase connection failed"
- Verifica que las credenciales en Railway son correctas
- Asegúrate de NO tener espacios extra al copiar las keys

---

## 🎉 ¡LISTO!

**Sistema backend completo funcionando en producción.**

Próximos pasos opcionales:
1. Configurar Stripe para pagos
2. Integrar WhatsApp para notificaciones
3. Añadir Vapi.ai para llamadas IA
4. Configurar dominio personalizado (api.cerrajerosya.es)

---

**¿Necesitas ayuda?** Revisa los logs de Railway y consulta el README.
