const { sequelize, User } = require('./models');
sequelize.sync().then(async () => {
    const users = await User.findAll();
    if (users.length === 0) {
        console.log('No users found.');
    } else {
        users.forEach(u => console.log(`Email: ${u.email}`));
    }
    process.exit(0);
}).catch(e => {
    console.error(e);
    process.exit(1);
});
