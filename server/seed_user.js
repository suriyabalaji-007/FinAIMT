const { sequelize, User } = require('./models');
const bcrypt = require('bcrypt');
sequelize.sync().then(async () => {
    const hashedPassword = await bcrypt.hash('password123', 10);
    const hashedPin = await bcrypt.hash('123456', 10);
    const user = await User.create({
        name: 'Suriya K',
        email: 'suriyadev@example.com',
        phone: '1234567890',
        password: hashedPassword,
        transactionPin: hashedPin
    });
    console.log('User created: ' + user.email);
    process.exit(0);
}).catch(e => {
    console.error(e);
    process.exit(1);
});
