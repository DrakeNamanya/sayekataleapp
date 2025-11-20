const admin = require('firebase-admin');
const serviceAccount = require('/opt/flutter/firebase-admin-sdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkSubscription() {
  try {
    // Find user by email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', 'drnamanya@gmail.com')
      .limit(1)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('❌ User not found with email: drnamanya@gmail.com');
      process.exit(1);
    }
    
    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();
    
    console.log('✅ Found user:', userId);
    console.log('   Name:', userData.name);
    console.log('   Email:', userData.email);
    console.log('   Role:', userData.role);
    
    // Check subscriptions
    const subscriptionsSnapshot = await db.collection('subscriptions')
      .where('userId', '==', userId)
      .where('type', '==', 'smeDirectory')
      .get();
    
    console.log('\n📋 Current Subscriptions:');
    if (subscriptionsSnapshot.empty) {
      console.log('   No active subscriptions found');
    } else {
      subscriptionsSnapshot.forEach(doc => {
        const sub = doc.data();
        console.log(`   Subscription ID: ${doc.id}`);
        console.log(`   Status: ${sub.status}`);
        console.log(`   Start: ${sub.startDate?.toDate()}`);
        console.log(`   End: ${sub.endDate?.toDate()}`);
        console.log(`   Payment Method: ${sub.paymentMethod}`);
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkSubscription();
