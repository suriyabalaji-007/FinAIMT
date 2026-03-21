const { sequelize, User } = require('./models');
const { transferFunds } = require('./services/paymentService');

async function testAtomicity() {
    console.log('--- Starting Concurrent Transaction Atomicity Test ---');
    await sequelize.sync();

    // Create two users with $1000 each (100,000 paise/cents)
    const initialBalance = 100000;
    const userA = await User.create({
        name: 'Atomicity Test User A',
        phone: '+919999999901',
        balance: initialBalance,
        transactionPin: '1234',
        isKycVerified: true,
    });

    const userB = await User.create({
        name: 'Atomicity Test User B',
        phone: '+919999999902',
        balance: initialBalance,
        transactionPin: '1234',
        isKycVerified: true,
    });

    console.log(`Initial Balances: User A: ${userA.balance}, User B: ${userB.balance}`);

    const transferAmount = 1000; // $10 per transfer
    const numTransfers = 100;
    console.log(`Initiating ${numTransfers} concurrent transfers of $10 from User A to User B...`);

    const promises = [];
    for (let i = 0; i < numTransfers; i++) {
        // Fire all transfers asynchronously without awaiting in the loop
        promises.push(
            transferFunds(userA.id, userB.id, transferAmount)
                .catch(err => console.error(`Transfer ${i} failed:`, err.message))
        );
    }

    // Wait for all concurrent transfers to complete
    await Promise.all(promises);

    // Fetch updated balances
    const updatedUserA = await User.findByPk(userA.id);
    const updatedUserB = await User.findByPk(userB.id);

    console.log(`\nFinal Balances after ${numTransfers} transfers:`);
    console.log(`User A: ${updatedUserA.balance} (Expected: 0)`);
    console.log(`User B: ${updatedUserB.balance} (Expected: 200000)`);

    const totalBefore = initialBalance * 2;
    const totalAfter = Number(updatedUserA.balance) + Number(updatedUserB.balance);
    console.log(`Total Money Before: ${totalBefore}`);
    console.log(`Total Money After:  ${totalAfter}`);

    if (totalBefore === totalAfter && Number(updatedUserA.balance) === 0) {
        console.log('✅ ATOMICITY TEST PASSED: No money lost or created during concurrent transactions.');
    } else {
        console.log('❌ ATOMICITY TEST FAILED: Balance mismatch detected due to race conditions.');
    }

    // Cleanup
    await User.destroy({ where: { id: [userA.id, userB.id] } });

    process.exit(0);
}

testAtomicity().catch(err => {
    console.error('Test execution error:', err);
    process.exit(1);
});
