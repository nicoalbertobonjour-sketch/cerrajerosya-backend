// ============================================
// CERRAJEROSYA.ES - BACKEND SERVER
// Main entry point
// ============================================

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

// Routes
const leadsRoutes = require('./src/routes/leads.routes');
const professionalsRoutes = require('./src/routes/professionals.routes');
const transactionsRoutes = require('./src/routes/transactions.routes');
const analyticsRoutes = require('./src/routes/analytics.routes');
const webhooksRoutes = require('./src/routes/webhooks.routes');

// Utils
const logger = require('./src/utils/logger');
const { handleError } = require('./src/utils/errors');

// ============================================
// APP SETUP
// ============================================

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================
// MIDDLEWARE
// ============================================

// Security
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));

// CORS
const corsOptions = {
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting global
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 min
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: 'Demasiadas peticiones desde esta IP, por favor intenta de nuevo más tarde.',
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api/', limiter);

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});

// ============================================
// ROUTES
// ============================================

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV,
    version: '1.0.0'
  });
});

// API routes
app.use('/api', leadsRoutes);
app.use('/api', professionalsRoutes);
app.use('/api', transactionsRoutes);
app.use('/api', analyticsRoutes);
app.use('/api', webhooksRoutes);

// Root
app.get('/', (req, res) => {
  res.json({
    name: 'cerrajerosya.es API',
    version: '1.0.0',
    status: 'online',
    documentation: 'https://api.cerrajerosya.es/docs',
    endpoints: {
      leads: '/api/leads',
      professionals: '/api/professionals',
      transactions: '/api/transactions',
      analytics: '/api/analytics',
      webhooks: '/api/webhooks'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.path
  });
});

// Global error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  
  const response = handleError(err);
  res.status(response.statusCode).json({
    success: false,
    error: response.message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// ============================================
// SERVER START
// ============================================

const server = app.listen(PORT, () => {
  logger.info(`🚀 Server running on port ${PORT}`);
  logger.info(`📍 Environment: ${process.env.NODE_ENV}`);
  logger.info(`🔗 API URL: ${process.env.API_URL || `http://localhost:${PORT}`}`);
  
  // Log configuration status
  const configs = {
    supabase: !!process.env.SUPABASE_URL,
    stripe: !!process.env.STRIPE_SECRET_KEY,
    whatsapp: !!process.env.WHATSAPP_API_TOKEN,
    vapi: !!process.env.VAPI_API_KEY,
    make: !!process.env.MAKE_WEBHOOK_URL
  };
  
  logger.info('📋 Configuration status:', configs);
  
  if (!configs.supabase) {
    logger.warn('⚠️  SUPABASE not configured - database operations will fail');
  }
  if (!configs.stripe) {
    logger.warn('⚠️  STRIPE not configured - payments will not work');
  }
  if (!configs.whatsapp) {
    logger.warn('⚠️  WHATSAPP not configured - notifications will not be sent');
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

module.exports = app;
