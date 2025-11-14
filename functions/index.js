/**
 * Firebase Cloud Functions for PawaPay Webhook Callbacks
 * 
 * These functions receive asynchronous payment status updates from PawaPay
 * and update Firestore accordingly.
 * 
 * Webhook URLs (after deployment):
 * - Deposits: https://YOUR-REGION-YOUR-PROJECT-ID.cloudfunctions.net/pawaPayDepositCallback
 * - Payouts: https://YOUR-REGION-YOUR-PROJECT-ID.cloudfunctions.net/pawaPayPayoutCallback
 * - Refunds: https://YOUR-REGION-YOUR-PROJECT-ID.cloudfunctions.net/pawaPayRefundCallback
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * PawaPay Deposit Callback Handler
 * 
 * Receives webhook when deposit status changes (COMPLETED, FAILED, etc.)
 * Updates transaction status and wallet balance in Firestore
 * 
 * Configure this URL in PawaPay Dashboard:
 * https://dashboard.sandbox.pawapay.io/settings/callbacks
 */
exports.pawaPayDepositCallback = functions.https.onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const callbackData = req.body;
    
    console.log('📥 PawaPay Deposit Callback Received:', JSON.stringify(callbackData));

    // Extract data from PawaPay callback
    const depositId = callbackData.depositId;
    const status = callbackData.status; // COMPLETED, FAILED, etc.
    const amount = parseFloat(callbackData.amount);
    const correspondent = callbackData.correspondent;
    const failureReason = callbackData.failureReason;

    if (!depositId || !status) {
      console.error('❌ Invalid callback data: missing depositId or status');
      return res.status(400).json({ error: 'Invalid callback data' });
    }

    // Find transaction by reference ID (depositId)
    const transactionsRef = db.collection('transactions');
    const querySnapshot = await transactionsRef
      .where('reference_id', '==', depositId)
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      console.warn(`⚠️ Transaction not found for depositId: ${depositId}`);
      return res.status(404).json({ error: 'Transaction not found' });
    }

    const transactionDoc = querySnapshot.docs[0];
    const transactionData = transactionDoc.data();
    const walletId = transactionData.wallet_id;

    // Handle different statuses
    if (status === 'COMPLETED' || status === 'ACCEPTED') {
      console.log(`✅ Deposit COMPLETED: ${depositId}, Amount: UGX ${amount}`);

      // Update transaction status to completed
      await transactionDoc.ref.update({
        status: 'completed',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update wallet balance
      const walletRef = db.collection('wallets').doc(walletId);
      const walletDoc = await walletRef.get();

      if (walletDoc.exists) {
        const currentBalance = walletDoc.data().balance || 0;
        const currentPending = walletDoc.data().pending_balance || 0;

        await walletRef.update({
          balance: currentBalance + amount,
          pending_balance: Math.max(0, currentPending - amount),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`💰 Wallet updated: Balance +${amount} UGX`);
      }

    } else if (status === 'FAILED' || status === 'REJECTED') {
      console.log(`❌ Deposit FAILED: ${depositId}, Reason: ${failureReason}`);

      // Update transaction status to failed
      await transactionDoc.ref.update({
        status: 'failed',
        description: failureReason || 'Payment failed',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Remove from pending balance
      const walletRef = db.collection('wallets').doc(walletId);
      const walletDoc = await walletRef.get();

      if (walletDoc.exists) {
        const currentPending = walletDoc.data().pending_balance || 0;

        await walletRef.update({
          pending_balance: Math.max(0, currentPending - amount),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    // Send success response to PawaPay
    return res.status(200).json({
      success: true,
      message: 'Callback processed successfully',
      depositId: depositId,
      status: status,
    });

  } catch (error) {
    console.error('❌ Error processing deposit callback:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

/**
 * PawaPay Payout Callback Handler
 * 
 * Receives webhook when payout status changes
 * Updates transaction status in Firestore
 */
exports.pawaPayPayoutCallback = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const callbackData = req.body;
    
    console.log('📤 PawaPay Payout Callback Received:', JSON.stringify(callbackData));

    const payoutId = callbackData.payoutId;
    const status = callbackData.status;
    const amount = parseFloat(callbackData.amount);
    const failureReason = callbackData.failureReason;

    if (!payoutId || !status) {
      return res.status(400).json({ error: 'Invalid callback data' });
    }

    // Find transaction by reference ID (payoutId)
    const transactionsRef = db.collection('transactions');
    const querySnapshot = await transactionsRef
      .where('reference_id', '==', payoutId)
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      console.warn(`⚠️ Transaction not found for payoutId: ${payoutId}`);
      return res.status(404).json({ error: 'Transaction not found' });
    }

    const transactionDoc = querySnapshot.docs[0];
    const transactionData = transactionDoc.data();
    const walletId = transactionData.wallet_id;

    if (status === 'COMPLETED' || status === 'ACCEPTED') {
      console.log(`✅ Payout COMPLETED: ${payoutId}, Amount: UGX ${amount}`);

      // Update transaction status
      await transactionDoc.ref.update({
        status: 'completed',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

    } else if (status === 'FAILED' || status === 'REJECTED') {
      console.log(`❌ Payout FAILED: ${payoutId}, Reason: ${failureReason}`);

      // Update transaction status
      await transactionDoc.ref.update({
        status: 'failed',
        description: failureReason || 'Payout failed',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Refund amount to wallet (payout failed, return money)
      const walletRef = db.collection('wallets').doc(walletId);
      const walletDoc = await walletRef.get();

      if (walletDoc.exists) {
        const currentBalance = walletDoc.data().balance || 0;

        await walletRef.update({
          balance: currentBalance + amount, // Return failed payout amount
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`💰 Wallet refunded: Balance +${amount} UGX (payout failed)`);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Callback processed successfully',
      payoutId: payoutId,
      status: status,
    });

  } catch (error) {
    console.error('❌ Error processing payout callback:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

/**
 * PawaPay Refund Callback Handler
 * 
 * Receives webhook when refund status changes
 * Updates transaction status and wallet balance
 */
exports.pawaPayRefundCallback = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const callbackData = req.body;
    
    console.log('🔄 PawaPay Refund Callback Received:', JSON.stringify(callbackData));

    const refundId = callbackData.refundId;
    const depositId = callbackData.depositId;
    const status = callbackData.status;
    const amount = parseFloat(callbackData.amount);
    const failureReason = callbackData.failureReason;

    if (!refundId || !status) {
      return res.status(400).json({ error: 'Invalid callback data' });
    }

    // Find original deposit transaction
    const transactionsRef = db.collection('transactions');
    const querySnapshot = await transactionsRef
      .where('reference_id', '==', depositId)
      .limit(1)
      .get();

    if (querySnapshot.empty) {
      console.warn(`⚠️ Original transaction not found for depositId: ${depositId}`);
      return res.status(404).json({ error: 'Transaction not found' });
    }

    const originalTransactionDoc = querySnapshot.docs[0];
    const originalTransactionData = originalTransactionDoc.data();
    const walletId = originalTransactionData.wallet_id;

    if (status === 'COMPLETED' || status === 'ACCEPTED') {
      console.log(`✅ Refund COMPLETED: ${refundId}, Amount: UGX ${amount}`);

      // Create refund transaction
      await transactionsRef.add({
        wallet_id: walletId,
        type: 'refund',
        amount: amount,
        status: 'completed',
        reference_id: refundId,
        description: `Refund for deposit ${depositId}`,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Deduct from wallet balance (refund = money goes back to customer's mobile money)
      const walletRef = db.collection('wallets').doc(walletId);
      const walletDoc = await walletRef.get();

      if (walletDoc.exists) {
        const currentBalance = walletDoc.data().balance || 0;

        await walletRef.update({
          balance: Math.max(0, currentBalance - amount),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`💰 Wallet updated: Balance -${amount} UGX (refunded)`);
      }

    } else if (status === 'FAILED' || status === 'REJECTED') {
      console.log(`❌ Refund FAILED: ${refundId}, Reason: ${failureReason}`);

      // Create failed refund transaction
      await transactionsRef.add({
        wallet_id: walletId,
        type: 'refund',
        amount: amount,
        status: 'failed',
        reference_id: refundId,
        description: `Refund failed: ${failureReason}`,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Refund callback processed successfully',
      refundId: refundId,
      status: status,
    });

  } catch (error) {
    console.error('❌ Error processing refund callback:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});
