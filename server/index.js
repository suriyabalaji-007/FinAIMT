require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const bcrypt = require('bcrypt');
const { sequelize, User } = require('./models');
const { transferFunds } = require('./services/paymentService');
const verifyTransactionPin = require('./middleware/pinAuth');
const stripeRoutes = require('./routes/stripe');
const { init: initSocket, sendNotification } = require('./socket/notificationHandler');

const app = express();
const server = http.createServer(app);
const io = initSocket(server);

app.use(express.json({
    verify: (req, res, buf) => {
        if (req.originalUrl.startsWith('/api/stripe/webhook')) {
            req.rawBody = buf;
        }
    }
}));
app.use(cors());

const { tradeAsset } = require('./services/investmentService');
const { payEMI, updateTaxAnalytics } = require('./services/financeService');
const { Investment, Loan, FinancialMetric } = require('./models');

// --- SIMULATIONS ---

// 1. Price Simulation
const marketPrices = {
    'RELIANCE': 285000,
    'HDFC_FUND': 542000,
    'GOLD': 115000,
    'PPF': 1620000,
    'LIC': 150000
};

setInterval(() => {
    Object.keys(marketPrices).forEach(key => {
        const volatility = (Math.random() - 0.5) * 0.01;
        marketPrices[key] = Math.round(marketPrices[key] * (1 + volatility));
    });
    io.emit('price_update', marketPrices);
}, 5000);

// 2. Expense Simulation (Random small expenses every 30s)
const categories = ['Food', 'Bills', 'Entertainment', 'Shopping'];
setInterval(async () => {
    // We pick a "default" user for demo purposes or broadcast to all
    const users = await User.findAll();
    for (const user of users) {
        if (Math.random() > 0.7) { // 30% chance for an expense
            const amount = Math.floor(Math.random() * 50000); // Up to ₹500
            const cat = categories[Math.floor(Math.random() * categories.length)];
            
            await FinancialMetric.create({
                userId: user.id,
                metricType: 'expense',
                value: amount,
                category: cat
            });

            user.balance -= amount;
            await user.save();

            // Notify client to refresh balance and charts
            io.to(user.id).emit('finance_update', { type: 'EXPENSE', amount, category: cat });
        }
    }
}, 30000);

// --- ROUTES ---

app.use('/api/stripe', stripeRoutes);

// Investment Routes
app.post('/api/investments/trade', async (req, res) => {
    const { userId, assetId, assetName, category, quantity, price, side } = req.body;
    try {
        const result = await tradeAsset(userId, assetId, assetName, category, quantity, price, side);
        const portfolio = await Investment.findAll({ where: { userId } });
        io.to(userId).emit('portfolio_update', portfolio);
        res.json(result);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// Finance (Loans & Metrics) Routes
app.post('/api/finance/pay-emi', async (req, res) => {
    const { userId, loanId } = req.body;
    try {
        const result = await payEMI(userId, loanId);
        const updatedLoans = await Loan.findAll({ where: { userId } });
        io.to(userId).emit('loans_update', updatedLoans);
        res.json(result);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

app.get('/api/finance/loans/:userId', async (req, res) => {
    try {
        const loans = await Loan.findAll({ where: { userId: req.params.userId } });
        res.json(loans);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/finance/metrics/:userId', async (req, res) => {
    try {
        const metrics = await FinancialMetric.findAll({ where: { userId: req.params.userId } });
        res.json(metrics);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// 1. Register / Create User (with hashed PIN)
app.post('/api/users', async (req, res) => {
    const { name, phone, email, transactionPin } = req.body;
    try {
        const hashedPin = await bcrypt.hash(transactionPin.toString(), 10);
        const user = await User.create({ name, phone, email, transactionPin: hashedPin });
        res.status(201).json({ id: user.id, name: user.name, balance: user.balance });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// 2. Transfer Funds (Protected by PIN)
app.post('/api/transfer', verifyTransactionPin, async (req, res) => {
    const { receiverId, amount } = req.body;
    const senderId = req.user.id;

    try {
        const transaction = await transferFunds(senderId, receiverId, amount);

        // Notification for Receiver
        sendNotification(receiverId, {
            type: 'PAYMENT_RECEIVED',
            amount,
            senderName: req.user.name,
            transactionId: transaction.id
        });

        res.json({ success: true, transactionId: transaction.id });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// 3. Get User Profile & Balance
app.get('/api/users/:id', async (req, res) => {
    try {
        const user = await User.findByPk(req.params.id, {
            attributes: ['id', 'name', 'phone', 'email', 'balance', 'isKycVerified']
        });
        if (!user) return res.status(404).json({ error: 'User not found' });
        res.json(user);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// --- SERVER INIT ---
const PORT = process.env.PORT || 3000;

sequelize.sync({ alter: true }).then(() => {
    console.log('Database synced');
    server.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}).catch(err => {
    console.error('Unable to sync database:', err);
});
