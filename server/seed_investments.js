const { sequelize, User, Investment } = require('./models');
const bcrypt = require('bcrypt');

sequelize.sync().then(async () => {
    const email = 'suriyadev@example.com';
    let user = await User.findOne({ where: { email } });
    
    if (!user) {
        const hashedPassword = await bcrypt.hash('password123', 10);
        const hashedPin = await bcrypt.hash('123456', 10);
        user = await User.create({
            name: 'Suriya K',
            email: email,
            phone: '1234567890',
            password: hashedPassword,
            transactionPin: hashedPin
        });
    }

    // Set a generous balance of ₹1,00,000 (10,000,000 paise)
    user.balance = 10000000;
    await user.save();

    // Clear existing for fresh seed
    await Investment.destroy({ where: { userId: user.id } });

    // Seed some initial investments
    await Investment.create({
        userId: user.id,
        assetId: 'RELIANCE',
        assetName: 'Reliance Industries',
        category: 'Stocks',
        quantity: 10,
        averagePrice: 280000 // ₹2,800.00 in paise
    });

    await Investment.create({
        userId: user.id,
        assetId: 'NIFTY50',
        assetName: 'NIFTY 50 Index',
        category: 'Index',
        quantity: 1,
        averagePrice: 2200000 // ₹22,000.00
    });

    console.log('Seeded suriyadev@example.com with balance and investments');
    process.exit(0);
}).catch(e => {
    console.error(e);
    process.exit(1);
});
