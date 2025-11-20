const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('/opt/flutter/firebase-admin-sdk.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function checkData() {
  try {
    const userId = 'SccSSc08HbQUIYH731HvGhgSJNX2';
    
    console.log('\n========================================');
    console.log('🔍 SUBSCRIPTION & TRANSACTION DIAGNOSTIC');
    console.log('========================================\n');
    
    // Check subscription
    const subDoc = await db.collection('subscriptions').doc(userId).get();
    if (subDoc.exists) {
      const data = subDoc.data();
      console.log('📋 SUBSCRIPTION DATA:');
      console.log('  Document ID:', subDoc.id);
      console.log('  Status:', data.status, data.status === 'pending' ? '⚠️ PENDING (Not Active)' : data.status === 'active' ? '✅ ACTIVE' : '❌ ' + data.status);
      console.log('  Type:', data.type);
      console.log('  Amount:', data.amount, 'UGX');
      console.log('  Payment Method:', data.payment_method);
      console.log('  Payment Reference:', data.payment_reference);
      console.log('  Start Date:', data.start_date?.toDate().toISOString());
      console.log('  End Date:', data.end_date?.toDate().toISOString());
      console.log('  Created At:', data.created_at?.toDate().toISOString());
      
      const now = new Date();
      const endDate = data.end_date?.toDate();
      const isExpired = now > endDate;
      const isPending = data.status === 'pending';
      
      console.log('\n  ⚠️ ISSUE DETECTED:');
      if (isPending) {
        console.log('     - Subscription status is PENDING');
        console.log('     - This means payment was NOT completed');
        console.log('     - Webhook did NOT activate the subscription');
        console.log('     - User should NOT have premium access');
      }
      if (!isExpired) {
        console.log('     - End date is in the future (' + Math.floor((endDate - now) / (1000 * 60 * 60 * 24)) + ' days remaining)');
      }
    } else {
      console.log('❌ No subscription found');
    }
    
    // Check transactions
    console.log('\n💰 RECENT TRANSACTIONS:');
    const txSnapshot = await db.collection('transactions')
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get();
    
    if (txSnapshot.empty) {
      console.log('  No transactions found');
    } else {
      txSnapshot.forEach((doc, index) => {
        const tx = doc.data();
        if (index > 0) console.log('');
        console.log(`  Transaction ${index + 1}:`);
        console.log('    ID:', doc.id);
        console.log('    Status:', tx.status, tx.status === 'initiated' ? '⚠️ NOT COMPLETED' : tx.status === 'completed' ? '✅ COMPLETED' : '');
        console.log('    Amount:', tx.amount, 'UGX');
        console.log('    Type:', tx.type);
        console.log('    User ID:', tx.userId);
        console.log('    Phone:', tx.metadata?.phone_number || 'N/A');
        console.log('    Operator:', tx.metadata?.operator || 'N/A');
        console.log('    Deposit ID:', tx.metadata?.deposit_id || 'N/A');
        console.log('    Created:', tx.createdAt?.toDate().toISOString());
      });
    }
    
    console.log('\n========================================');
    console.log('🔍 ROOT CAUSE ANALYSIS');
    console.log('========================================\n');
    
    if (subDoc.exists && subDoc.data().status === 'pending') {
      console.log('✅ GOOD NEWS: Subscription is correctly PENDING');
      console.log('   - This means payment was NOT completed');
      console.log('   - App should NOT grant premium access');
      console.log('\n⚠️ PROBLEM: App is granting access anyway!');
      console.log('   - Check: getActiveSubscription() method');
      console.log('   - Check: hasActiveSMEDirectorySubscription() method');
      console.log('   - Check: Subscription.isActive getter');
      console.log('\n🔧 LIKELY ISSUE:');
      console.log('   - App may be checking if subscription EXISTS');
      console.log('   - Instead of checking if subscription is ACTIVE');
      console.log('   - OR: endDate is set to future date even though status is pending');
    }
    
    console.log('\n========================================');
    console.log('📱 PAWAPAY INTEGRATION CHECK');
    console.log('========================================\n');
    
    console.log('❌ NO MOBILE MONEY PROMPT ISSUE:');
    console.log('   Possible causes:');
    console.log('   1. Wrong PawaPay API endpoint (sandbox vs production)');
    console.log('   2. Incorrect webhook URL configured');
    console.log('   3. PawaPay API rejecting requests');
    console.log('   4. Phone number not registered for mobile money');
    console.log('\n✅ DEPLOYED WEBHOOK URL (Correct):');
    console.log('   https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook');
    console.log('\n⚠️ CONFIGURED WEBHOOK URL (In app code):');
    console.log('   https://pawapay-webhook-713040690605.us-central1.run.app/api/pawapay/webhook');
    console.log('   ^^ THIS IS WRONG! Not using Firebase Functions URL');
    
    console.log('\n========================================');
    console.log('🔧 RECOMMENDED FIXES');
    console.log('========================================\n');
    
    console.log('1. Update environment.dart webhook URL to:');
    console.log('   https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook');
    console.log('\n2. Verify PawaPay Dashboard callback URL matches:');
    console.log('   https://us-central1-sayekataleapp.cloudfunctions.net/pawaPayWebhook');
    console.log('\n3. Check app subscription logic:');
    console.log('   - Ensure checking status == "active" AND endDate > now');
    console.log('   - Not just checking if subscription document exists');
    console.log('\n4. Test with real Uganda mobile money number');
    console.log('   - MTN: 077/078/031/039/076/079');
    console.log('   - Airtel: 070/074/075');
    
    console.log('\n========================================\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

checkData();
