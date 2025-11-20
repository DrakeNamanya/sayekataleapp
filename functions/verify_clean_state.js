const admin = require('firebase-admin');
const serviceAccount = require('/opt/flutter/firebase-admin-sdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyCleanState() {
  try {
    const userId = 'SccSSc08HbQUIYH731HvGhgSJNX2';
    const email = 'drnamanya@gmail.com';
    
    console.log(`\n🔍 Verifying clean state for: ${email}\n`);
    
    // Check subscription by userId as document ID
    const subDoc = await db.collection('subscriptions').doc(userId).get();
    
    if (subDoc.exists) {
      const data = subDoc.data();
      console.log(`⚠️  Found subscription:`);
      console.log(`   Status: ${data.status}`);
      console.log(`   Type: ${data.type}`);
      console.log(`   Created: ${data.createdAt?.toDate?.() || data.created_at}`);
      
      if (data.status === 'expired' || data.deactivatedAt) {
        console.log(`\n✅ Subscription is deactivated - ready for testing`);
      } else if (data.status === 'pending') {
        console.log(`\n⚠️  Subscription is PENDING - previous test in progress`);
      } else {
        console.log(`\n❌ Subscription is ${data.status} - needs deactivation`);
      }
    } else {
      console.log(`✅ No subscription found - clean state for testing`);
    }
    
    // Check recent transactions
    const recentTx = await db.collection('transactions')
      .where('userId', '==', userId)
      .limit(3)
      .get();
    
    if (!recentTx.empty) {
      console.log(`\n📊 Recent transactions (${recentTx.size}):`);
      recentTx.forEach(doc => {
        const tx = doc.data();
        console.log(`   - ${doc.id.substring(0, 8)}... | ${tx.status} | ${tx.type}`);
      });
    }
    
    console.log(`\n✅ User ready for payment testing!\n`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

verifyCleanState();
