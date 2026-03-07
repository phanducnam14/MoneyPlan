require('dotenv').config();
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');

const { connectDb } = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const incomeRoutes = require('./routes/incomeRoutes');
const adminRoutes = require('./routes/adminRoutes');
const swaggerSpec = require('./swagger');

const app = express();
app.use(cors({
  origin: true,
  credentials: true,
}));
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/expenses', expenseRoutes);
app.use('/incomes', incomeRoutes);
app.use('/admin', adminRoutes);
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

const port = process.env.PORT || 3000;

connectDb()
  .then(() => app.listen(port, () => console.log(`API running on :${port}`)))
  .catch((error) => console.error(error));
