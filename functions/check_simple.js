const admin = require('firebase-admin');
const serviceAccount = require('/opt/flutter/firebase-admin-sdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkData() {
  try {
    const userId = 'SccSSc08HbQUIYH731HvGhgSJNX2';
    
    console.log('\n📊 Checking Latest Test Data\n');
    
    // Check transactions without ordering
    const txQuery = await db.collection('transactions')
      .where('userId', '==', userId)
      .limit(5)
      .get();
    
    console.log(`Transactions: ${txQuery.size} found`);
    if (!txQuery.empty) {
      const latestTx = txQuery.docs[0].data();
      console.log(`  Latest Status: ${latestTx.status}`);
      console.log(`  Latest Type: ${latestTx.type}`);
      console.log(`  Latest Amount: ${latestTx.amount}`);
    }
    
    // Check subscription
    const subDoc = await db.collection('subscriptions').doc(userId).get();
    console.log(`\nSubscription: ${subDoc.exists ? 'EXISTS' : 'MISSING'}`);
    
    if (subDoc.exists) {
      const sub = subDoc.data();
      console.log(`  Status: ${sub.status}`);
      console.log(`  Payment Ref: ${sub.payment_reference}`);
    }
    
    // List all collection names to verify subscriptions collection exists
    const collections = await db.listCollections();
    const collectionNames = collections.map(col => col.id);
    console.log(`\n📂 Collections in database: ${collectionNames.length}`);
    console.log(`   Has 'subscriptions'? ${collectionNames.includes('subscriptions') ? 'YES' : 'NO'}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

checkData();
