const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para parsing de JSON
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'DevOps AKS Demo Application',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    description: 'CI/CD Pipeline com GitHub Actions + ACR + AKS'
  });
});

// Info endpoint
app.get('/info', (req, res) => {
  res.json({
    hostname: require('os').hostname(),
    platform: process.platform,
    nodeVersion: process.version,
    memory: {
      total: `${(require('os').totalmem() / 1024 / 1024 / 1024).toFixed(2)} GB`,
      free: `${(require('os').freemem() / 1024 / 1024 / 1024).toFixed(2)} GB`
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  process.exit(0);
});
