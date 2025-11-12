import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/wallet.dart' as wallet_model;
import 'pawapay_service.dart';

/// Wallet Service for managing user wallets and transactions
class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PawaPayService _pawaPayService;
  
  WalletService({required PawaPayService pawaPayService})
      : _pawaPayService = pawaPayService;
  
  // ============================================================================
  // WALLET MANAGEMENT
  // ============================================================================
  
  /// Get or create wallet for user
  Future<wallet_model.Wallet> getOrCreateWallet(String userId) async {
    try {
      final walletDoc = await _firestore.collection('wallets').doc(userId).get();
      
      if (walletDoc.exists) {
        return wallet_model.Wallet.fromFirestore(walletDoc.data()!, walletDoc.id);
      }
      
      // Create new wallet
      final newWallet = wallet_model.Wallet(
        id: userId,
        userId: userId,
        balance: 0.0,
        pendingBalance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('wallets').doc(userId).set(newWallet.toFirestore());
      
      if (kDebugMode) {
        debugPrint('✅ Wallet created for user: $userId');
      }
      
      return newWallet;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting/creating wallet: $e');
      }
      rethrow;
    }
  }
  
  /// Stream wallet updates
  /// Note: Call getOrCreateWallet() first to ensure wallet exists before streaming
  Stream<wallet_model.Wallet> streamWallet(String userId) {
    return _firestore
        .collection('wallets')
        .doc(userId)
        .snapshots()
        .map((doc) {
          // Handle case where document might not exist
          if (!doc.exists || doc.data() == null) {
            // Return default wallet if document doesn't exist
            // This should rarely happen if getOrCreateWallet is called first
            if (kDebugMode) {
              debugPrint('⚠️ Wallet document does not exist for user $userId, returning default');
            }
            return wallet_model.Wallet(
              id: userId,
              userId: userId,
              balance: 0.0,
              pendingBalance: 0.0,
              currency: 'UGX',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return wallet_model.Wallet.fromFirestore(doc.data()!, doc.id);
        });
  }
  
  // ============================================================================
  // DEPOSIT (Add money to wallet via PawaPay)
  // ============================================================================
  
  /// Initiate deposit via PawaPay
  Future<Map<String, dynamic>> initiateDeposit({
    required String userId,
    required double amount,
    required String phoneNumber,
    required String provider, // 'MTN_MOMO_UGA' or 'AIRTEL_OAPI_UGA'
    String? userName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('💰 Initiating deposit: UGX $amount for user $userId');
      }
      
      // Call PawaPay to initiate deposit
      final result = await _pawaPayService.initiateDeposit(
        amount: amount,
        currency: 'UGX',
        phoneNumber: phoneNumber,
        correspondentId: provider,
        description: 'Wallet deposit',
        customerName: userName,
      );
      
      if (result['success'] == true) {
        // Create pending transaction
        await _createTransaction(
          userId: userId,
          type: wallet_model.TransactionType.deposit,
          amount: amount,
          status: wallet_model.TransactionStatus.pending,
          referenceId: result['depositId'],
          description: 'Mobile money deposit',
        );
        
        // Update pending balance
        await _updatePendingBalance(userId, amount, add: true);
        
        return {
          'success': true,
          'transactionId': result['depositId'],
          'message': result['message'],
        };
      } else {
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Deposit initiation error: $e');
      }
      return {
        'success': false,
        'error': 'Failed to initiate deposit: $e',
      };
    }
  }
  
  /// Handle deposit callback from PawaPay
  Future<void> handleDepositCallback({
    required String depositId,
    required String status, // COMPLETED, FAILED, etc.
    required double amount,
    String? failureReason,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📥 Deposit callback: $depositId - Status: $status');
      }
      
      // Find transaction by reference ID
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('reference_id', isEqualTo: depositId)
          .limit(1)
          .get();
      
      if (transactionQuery.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Transaction not found for deposit: $depositId');
        }
        return;
      }
      
      final transactionDoc = transactionQuery.docs.first;
      final transaction = wallet_model.Transaction.fromMap(transactionDoc.data());
      
      if (status == 'COMPLETED') {
        // Update transaction status
        await _firestore.collection('transactions').doc(transactionDoc.id).update({
          'status': wallet_model.TransactionStatus.completed.toString().split('.').last,
        });
        
        // Add to wallet balance
        await _updateBalance(transaction.walletId, amount, add: true);
        
        // Remove from pending balance
        await _updatePendingBalance(transaction.walletId, amount, add: false);
        
        if (kDebugMode) {
          debugPrint('✅ Deposit completed: UGX $amount added to wallet');
        }
      } else if (status == 'FAILED') {
        // Update transaction status
        await _firestore.collection('transactions').doc(transactionDoc.id).update({
          'status': wallet_model.TransactionStatus.failed.toString().split('.').last,
          'description': failureReason ?? 'Payment failed',
        });
        
        // Remove from pending balance
        await _updatePendingBalance(transaction.walletId, amount, add: false);
        
        if (kDebugMode) {
          debugPrint('❌ Deposit failed: $failureReason');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error handling deposit callback: $e');
      }
    }
  }
  
  // ============================================================================
  // WITHDRAWAL (Send money from wallet via PawaPay)
  // ============================================================================
  
  /// Initiate withdrawal via PawaPay
  Future<Map<String, dynamic>> initiateWithdrawal({
    required String userId,
    required double amount,
    required String phoneNumber,
    required String provider,
    String? userName,
  }) async {
    try {
      // Check wallet balance
      final wallet = await getOrCreateWallet(userId);
      
      if (wallet.balance < amount) {
        return {
          'success': false,
          'error': 'Insufficient balance. Available: UGX ${wallet.balance.toStringAsFixed(0)}',
        };
      }
      
      if (kDebugMode) {
        debugPrint('💸 Initiating withdrawal: UGX $amount for user $userId');
      }
      
      // Call PawaPay to initiate payout
      final result = await _pawaPayService.initiatePayout(
        amount: amount,
        currency: 'UGX',
        phoneNumber: phoneNumber,
        correspondentId: provider,
        description: 'Wallet withdrawal',
        recipientName: userName,
      );
      
      if (result['success'] == true) {
        // Create pending transaction
        await _createTransaction(
          userId: userId,
          type: wallet_model.TransactionType.withdrawal,
          amount: amount,
          status: wallet_model.TransactionStatus.pending,
          referenceId: result['payoutId'],
          description: 'Mobile money withdrawal',
        );
        
        // Deduct from balance immediately
        await _updateBalance(userId, amount, add: false);
        
        return {
          'success': true,
          'transactionId': result['payoutId'],
          'message': result['message'],
        };
      } else {
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Withdrawal initiation error: $e');
      }
      return {
        'success': false,
        'error': 'Failed to initiate withdrawal: $e',
      };
    }
  }
  
  /// Handle payout callback from PawaPay
  Future<void> handlePayoutCallback({
    required String payoutId,
    required String status,
    required double amount,
    String? failureReason,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📤 Payout callback: $payoutId - Status: $status');
      }
      
      // Find transaction by reference ID
      final transactionQuery = await _firestore
          .collection('transactions')
          .where('reference_id', isEqualTo: payoutId)
          .limit(1)
          .get();
      
      if (transactionQuery.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Transaction not found for payout: $payoutId');
        }
        return;
      }
      
      final transactionDoc = transactionQuery.docs.first;
      final transaction = wallet_model.Transaction.fromMap(transactionDoc.data());
      
      if (status == 'COMPLETED') {
        // Update transaction status
        await _firestore.collection('transactions').doc(transactionDoc.id).update({
          'status': wallet_model.TransactionStatus.completed.toString().split('.').last,
        });
        
        if (kDebugMode) {
          debugPrint('✅ Withdrawal completed: UGX $amount sent');
        }
      } else if (status == 'FAILED') {
        // Update transaction status
        await _firestore.collection('transactions').doc(transactionDoc.id).update({
          'status': wallet_model.TransactionStatus.failed.toString().split('.').last,
          'description': failureReason ?? 'Payout failed',
        });
        
        // Refund to wallet balance
        await _updateBalance(transaction.walletId, amount, add: true);
        
        if (kDebugMode) {
          debugPrint('❌ Withdrawal failed, amount refunded: $failureReason');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error handling payout callback: $e');
      }
    }
  }
  
  // ============================================================================
  // TRANSACTIONS
  // ============================================================================
  
  /// Get user transactions
  Future<List<wallet_model.Transaction>> getTransactions(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('wallet_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => wallet_model.Transaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting transactions: $e');
      }
      return [];
    }
  }
  
  /// Stream user transactions
  Stream<List<wallet_model.Transaction>> streamTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('wallet_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => wallet_model.Transaction.fromMap(doc.data())).toList());
  }
  
  /// Create transaction record
  Future<String> _createTransaction({
    required String userId,
    required wallet_model.TransactionType type,
    required double amount,
    required wallet_model.TransactionStatus status,
    String? referenceId,
    String? orderId,
    String? description,
  }) async {
    try {
      final transaction = wallet_model.Transaction(
        id: '', // Will be set by Firestore
        walletId: userId,
        type: type,
        amount: amount,
        status: status,
        referenceId: referenceId,
        orderId: orderId,
        description: description,
        createdAt: DateTime.now(),
      );
      
      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toMap());
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating transaction: $e');
      }
      rethrow;
    }
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Update wallet balance
  Future<void> _updateBalance(String userId, double amount, {required bool add}) async {
    final walletRef = _firestore.collection('wallets').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      
      if (!walletDoc.exists) {
        throw Exception('Wallet not found');
      }
      
      final currentBalance = (walletDoc.data()!['balance'] ?? 0.0).toDouble();
      final newBalance = add ? currentBalance + amount : currentBalance - amount;
      
      transaction.update(walletRef, {
        'balance': newBalance < 0 ? 0 : newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }
  
  /// Update pending balance
  Future<void> _updatePendingBalance(String userId, double amount, {required bool add}) async {
    final walletRef = _firestore.collection('wallets').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      
      if (!walletDoc.exists) {
        throw Exception('Wallet not found');
      }
      
      final currentPending = (walletDoc.data()!['pending_balance'] ?? 0.0).toDouble();
      final newPending = add ? currentPending + amount : currentPending - amount;
      
      transaction.update(walletRef, {
        'pending_balance': newPending < 0 ? 0 : newPending,
        'updated_at': DateTime.now().toIso8601String(),
      });
    });
  }
}
