const admin = require('firebase-admin');
const serviceAccount = require('/opt/flutter/firebase-admin-sdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkLatestData() {
  try {
    const userId = 'SccSSc08HbQUIYH731HvGhgSJNX2';
    
    console.log('\n📊 Checking Firestore Data for drnamanya@gmail.com\n');
    
    // Check transactions
    const txQuery = await db.collection('transactions')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(3)
      .get();
    
    if (txQuery.empty) {
      console.log('❌ No transactions found');
    } else {
      console.log(`✅ Found ${txQuery.size} recent transaction(s):\n`);
      txQuery.forEach(doc => {
        const tx = doc.data();
        console.log(`  ID: ${doc.id}`);
        console.log(`  Type: ${tx.type}`);
        console.log(`  Status: ${tx.status}`);
        console.log(`  Amount: ${tx.amount}`);
        console.log(`  Operator: ${tx.operator || tx.paymentMethod}`);
        console.log(`  Created: ${tx.createdAt?.toDate?.()}`);
        console.log('');
      });
    }
    
    // Check subscription
    const subDoc = await db.collection('subscriptions').doc(userId).get();
    
    if (subDoc.exists) {
      console.log('✅ Subscription document found:\n');
      const sub = subDoc.data();
      console.log(`  Status: ${sub.status}`);
      console.log(`  Type: ${sub.type}`);
      console.log(`  Payment Method: ${sub.payment_method}`);
      console.log(`  Payment Reference: ${sub.payment_reference}`);
      console.log(`  Created: ${sub.created_at?.toDate?.() || sub.createdAt?.toDate?.()}`);
    } else {
      console.log('❌ No subscription document found');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

checkLatestData();
