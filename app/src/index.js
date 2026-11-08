const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para parsing de JSON
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Application metadata API
app.get('/api', (req, res) => {
  res.json({
    message: 'DevOps AKS Demo Application',
    version: require('../package.json').version,
    commit: process.env.GIT_SHA || null,
    imageTag: process.env.IMAGE_TAG || 'local',
    environment: process.env.NODE_ENV || 'development',
    description: 'CI/CD Pipeline com GitHub Actions + ACR + AKS'
  });
});

// Info endpoint
app.get('/info', (req, res) => {
  res.json({
    platform: process.platform,
    nodeVersion: process.version
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
    message: 'Unexpected error'
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
