const express = require('express');
const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/', (req, res) => {
  res.json({ message: 'API funcionando correctamente v2' });
});

app.get('/api/items', (req, res) => {
  res.json([
    { id: 1, nombre: 'Item uno' },
    { id: 2, nombre: 'Item dos' },
  ]);
});

module.exports = app;
