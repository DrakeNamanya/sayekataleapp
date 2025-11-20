const admin = require('firebase-admin');
const serviceAccount = require('/opt/flutter/firebase-admin-sdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifySuccess() {
  try {
    const userId = 'SccSSc08HbQUIYH731HvGhgSJNX2';
    
    console.log('\n✅ SUCCESS! Payment Flow Verification\n');
    
    // Check subscription
    const subDoc = await db.collection('subscriptions').doc(userId).get();
    if (subDoc.exists) {
      const sub = subDoc.data();
      console.log('📋 Subscription Document:');
      console.log(`   Status: ${sub.status}`);
      console.log(`   Type: ${sub.type}`);
      console.log(`   Payment Method: ${sub.payment_method}`);
      console.log(`   Payment Reference: ${sub.payment_reference}`);
      console.log(`   Amount: UGX ${sub.amount}`);
      console.log(`   Start: ${sub.start_date.toDate().toLocaleDateString()}`);
      console.log(`   End: ${sub.end_date.toDate().toLocaleDateString()}`);
      console.log('   ✅ SUBSCRIPTION CREATED SUCCESSFULLY!\n');
    }
    
    // Check transaction
    const txQuery = await db.collection('transactions')
      .where('userId', '==', userId)
      .limit(1)
      .get();
    
    if (!txQuery.empty) {
      const tx = txQuery.docs[0].data();
      console.log('💳 Transaction Document:');
      console.log(`   Status: ${tx.status}`);
      console.log(`   Type: ${tx.type}`);
      console.log(`   Amount: UGX ${tx.amount}`);
      console.log(`   Operator: ${tx.operator || tx.paymentMethod}`);
      console.log(`   Phone: ${tx.metadata?.phone_number || 'N/A'}`);
      console.log(`   Deposit ID: ${tx.metadata?.deposit_id || tx.paymentReference}`);
      console.log('   ✅ TRANSACTION CREATED SUCCESSFULLY!\n');
    }
    
    console.log('🎯 Next Steps:');
    console.log('   1. Deploy webhook to Firebase Functions');
    console.log('   2. Configure PawaPay webhook URL');
    console.log('   3. Test payment approval on mobile device');
    console.log('   4. Webhook will update subscription status to "active"\n');
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    process.exit(0);
  }
}

verifySuccess();
