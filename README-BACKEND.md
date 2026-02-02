# 🚀 CERRAJEROSYA.ES - BACKEND COMPLETO

Sistema backend completo listo para producción.

## 📦 ESTRUCTURA DEL PROYECTO

```
cerrajerosya-backend/
├── .env                          ← TUS CREDENCIALES (YA CONFIGURADO)
├── .gitignore
├── package.json
├── server.js                     ← ENTRY POINT
├── src/
│   ├── config/
│   │   └── supabase.js          ← Configuración Supabase
│   ├── controllers/
│   │   ├── leads.controller.js
│   │   ├── professionals.controller.js
│   │   ├── transactions.controller.js
│   │   └── analytics.controller.js
│   ├── services/
│   │   ├── assignment.engine.js  ← Motor de asignación con scoring
│   │   ├── notification.service.js
│   │   └── audit.service.js
│   ├── routes/
│   │   ├── leads.routes.js
│   │   ├── professionals.routes.js
│   │   ├── transactions.routes.js
│   │   ├── analytics.routes.js
│   │   └── webhooks.routes.js
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   └── validation.middleware.js
│   └── utils/
│       ├── logger.js
│       └── errors.js
└── README.md
```

## ⚡ QUICK START

### 1️⃣ Instalar dependencias

```bash
npm install
```

### 2️⃣ Configurar variables de entorno

El archivo `.env` ya está configurado con tus credenciales de Supabase:

✅ SUPABASE_URL
✅ SUPABASE_ANON_KEY  
✅ SUPABASE_SERVICE_KEY

**IMPORTANTE:** Completa las credenciales de Stripe si vas a usar pagos.

### 3️⃣ Ejecutar en desarrollo

```bash
npm run dev
```

El servidor arrancará en: `http://localhost:3000`

### 4️⃣ Verificar que funciona

Abre en el navegador: `http://localhost:3000/health`

Deberías ver:
```json
{
  "status": "ok",
  "timestamp": "2026-02-02T...",
  "environment": "development"
}
```

## 🚀 DEPLOYMENT A RAILWAY

### Método 1: Conectar con GitHub (Recomendado)

1. **Sube el código a GitHub:**

```bash
git init
git add .
git commit -m "Initial backend setup"
git remote add origin https://github.com/TU_USUARIO/cerrajerosya-backend.git
git push -u origin main
```

2. **Conecta Railway con GitHub:**
   - Ve a https://railway.app
   - New Project → Deploy from GitHub repo
   - Selecciona tu repositorio
   - Railway detectará Node.js automáticamente

3. **Configura variables de entorno:**
   - En Railway → Variables → Raw Editor
   - Copia y pega TODO el contenido de tu archivo `.env`
   - Save

4. **Deploy automático:**
   - Railway construirá y desplegará automáticamente
   - Te dará una URL: `https://cerrajerosya-backend-production.up.railway.app`

### Método 2: Railway CLI

```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Login
railway login

# Crear proyecto
railway init

# Deploy
railway up
```

## 📡 ENDPOINTS DISPONIBLES

### Health Check
```
GET /health
```

### Leads
```
POST   /api/leads              - Crear lead
GET    /api/leads              - Listar leads
GET    /api/leads/:id          - Obtener lead
POST   /api/leads/:id/assign   - Asignar lead (admin)
PATCH  /api/leads/:id/status   - Actualizar estado
POST   /api/leads/:id/cancel   - Cancelar lead
POST   /api/leads/:id/complete - Completar lead
```

### Professionals
```
GET    /api/professionals      - Listar profesionales
GET    /api/professionals/:id  - Obtener profesional
POST   /api/professionals      - Crear profesional
```

### Analytics
```
GET    /api/analytics/dashboard - Métricas del dashboard
```

## 🧪 TESTING

### Crear un lead de prueba

```bash
curl -X POST http://localhost:3000/api/leads \
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

### Obtener todos los leads

```bash
curl http://localhost:3000/api/leads
```

## 🔧 CONFIGURACIÓN

### Variables de Entorno Esenciales

```env
# Ya configuradas ✅
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_KEY

# Pendientes (opcional primera fase) ⏳
STRIPE_SECRET_KEY
WHATSAPP_API_TOKEN
VAPI_API_KEY
```

### Precios por Defecto

Puedes ajustar los precios base en `.env`:

```env
DEFAULT_LEAD_PRICE=25.00
URGENT_LEAD_MULTIPLIER=1.5
NIGHT_MULTIPLIER=1.3
```

## 📊 MOTOR DE ASIGNACIÓN

El sistema incluye un motor de asignación automática con scoring:

**SCORE = (reputation × 40) + (conversion_rate × 30) + (balance × 20) + (response_time × 10)**

Los leads con `urgency_level >= 4` se asignan automáticamente al profesional con mayor score.

## 🔐 SEGURIDAD

- ✅ Helmet para headers de seguridad
- ✅ CORS configurado
- ✅ Rate limiting
- ✅ Row Level Security en Supabase
- ✅ JWT para autenticación
- ✅ Service role key nunca expuesta al frontend

## 📝 LOGS

Los logs se escriben en:
- Console (desarrollo)
- `logs/app.log` (producción)

Nivel de log configurado en `.env`:
```env
LOG_LEVEL=info
```

## 🆘 TROUBLESHOOTING

### Error: "Missing SUPABASE_URL"
**Solución:** Verifica que el archivo `.env` está en la raíz del proyecto.

### Error: "Connection refused"
**Solución:** Verifica que Supabase está activo y las credenciales son correctas.

### Error en Railway: "Build failed"
**Solución:** Asegúrate de tener `package.json` con el script `"start": "node server.js"`.

## 📞 SOPORTE

Si tienes problemas:
1. Revisa los logs del servidor
2. Verifica las variables de entorno
3. Comprueba que Supabase tiene las tablas creadas

## ✅ CHECKLIST ANTES DE PRODUCCIÓN

- [ ] Base de datos Supabase creada (SQL ejecutado)
- [ ] Variables de entorno configuradas
- [ ] Backend desplegado en Railway
- [ ] Health check responde correctamente
- [ ] Test de crear lead exitoso
- [ ] Logs funcionando
- [ ] Stripe configurado (si usas pagos)

## 🎯 PRÓXIMOS PASOS

1. ✅ Configura Stripe para pagos
2. ✅ Integra WhatsApp para notificaciones
3. ✅ Conecta Make.com para automatización
4. ✅ Añade Vapi.ai para llamadas IA
5. ✅ Actualiza el frontend con la URL del backend

---

**¡Sistema listo para producción!** 🚀
