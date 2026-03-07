const swaggerJSDoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Smart Finance API',
      version: '1.0.0'
    },
    servers: [{ url: 'http://localhost:3000' }]
  },
  apis: []
};

module.exports = swaggerJSDoc(options);
