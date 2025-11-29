/**
 * Firebase Cloud Functions for SayeKatale App
 * 
 * Push Notification Triggers:
 * 1. New Order - Notify seller when buyer places order
 * 2. Order Confirmation - Notify buyer when seller confirms order
 * 3. New Message - Notify recipient when message received
 * 4. PSA Verification - Notify admin when PSA submits verification
 * 5. Low Stock Alert - Notify seller when product stock is low
 * 6. Delivery Update - Notify buyer on delivery status changes
 */

const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Get user's FCM token from Firestore
 * @param {string} userId - User ID
 * @return {Promise<string|null>} FCM token or null
 */
async function getUserFCMToken(userId) {
  try {
    const userDoc = await admin.firestore()
        .collection("users")
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      logger.warn(`User not found: ${userId}`);
      return null;
    }

    const fcmToken = userDoc.data()?.fcm_token;

    if (!fcmToken) {
      logger.warn(`No FCM token for user: ${userId}`);
      return null;
    }

    return fcmToken;
  } catch (error) {
    logger.error(`Error getting FCM token for user ${userId}:`, error);
    return null;
  }
}

/**
 * Send FCM push notification
 * @param {string} fcmToken - FCM device token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Custom data payload
 * @return {Promise<string>} Message ID
 */
async function sendFCMNotification(fcmToken, title, body, data = {}) {
  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: data,
      token: fcmToken,
      android: {
        notification: {
          sound: "default",
          priority: "high",
        },
      },
    };

    const response = await admin.messaging().send(message);
    logger.info(`✅ FCM notification sent: ${response}`);
    return response;
  } catch (error) {
    logger.error("❌ Error sending FCM notification:", error);
    throw error;
  }
}

/**
 * Create in-app notification in Firestore
 * @param {string} userId - Recipient user ID
 * @param {string} type - Notification type
 * @param {string} title - Notification title
 * @param {string} message - Notification message
 * @param {string} actionUrl - Action URL for navigation
 * @param {object} metadata - Additional metadata
 * @return {Promise<void>}
 */
async function createInAppNotification(userId, type, title, message, actionUrl = "", metadata = {}) {
  try {
    await admin.firestore().collection("notifications").add({
      user_id: userId,
      type: type,
      title: title,
      message: message,
      action_url: actionUrl,
      metadata: metadata,
      is_read: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`✅ In-app notification created for user: ${userId}`);
  } catch (error) {
    logger.error("❌ Error creating in-app notification:", error);
  }
}

// ============================================================================
// CLOUD FUNCTIONS - ORDER NOTIFICATIONS
// ============================================================================

/**
 * Trigger: New order created
 * Action: Notify seller (SME/PSA) that they received a new order
 */
exports.onNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data.data();
  const orderId = event.params.orderId;

  logger.info(`🛒 New order created: ${orderId}`);
  logger.info(`   Seller ID: ${order.seller_id}`);
  logger.info(`   Buyer: ${order.buyer_name}`);
  logger.info(`   Product: ${order.product_name}`);

  try {
    // Get seller's FCM token
    const sellerFCMToken = await getUserFCMToken(order.seller_id);

    if (!sellerFCMToken) {
      logger.warn(`Cannot send FCM - No token for seller: ${order.seller_id}`);
      // Still create in-app notification
      await createInAppNotification(
          order.seller_id,
          "order",
          "🛒 New Order Received!",
          `${order.buyer_name} ordered ${order.product_name}`,
          `/orders/${orderId}`,
          {order_id: orderId},
      );
      return;
    }

    // Send FCM push notification
    await sendFCMNotification(
        sellerFCMToken,
        "🛒 New Order Received!",
        `${order.buyer_name} ordered ${order.product_name} (${order.quantity} ${order.unit})`,
        {
          type: "order",
          order_id: orderId,
          action_url: `/orders/${orderId}`,
        },
    );

    // Also create in-app notification
    await createInAppNotification(
        order.seller_id,
        "order",
        "🛒 New Order Received!",
        `${order.buyer_name} ordered ${order.product_name}`,
        `/orders/${orderId}`,
        {order_id: orderId},
    );

    logger.info(`✅ Order notification sent to seller: ${order.seller_id}`);
  } catch (error) {
    logger.error("❌ Error sending order notification:", error);
  }
});

/**
 * Trigger: Order status updated to 'confirmed' or 'delivered'
 * Action: Notify buyer (SHG) about order status change
 */
exports.onOrderStatusUpdate = onDocumentUpdated("orders/{orderId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const orderId = event.params.orderId;

  // Only trigger if status changed
  if (beforeData.status === afterData.status) {
    return;
  }

  const newStatus = afterData.status;
  logger.info(`📦 Order status updated: ${orderId} → ${newStatus}`);

  try {
    let notificationTitle = "";
    let notificationBody = "";

    // Determine notification based on new status
    switch (newStatus) {
      case "confirmed":
        notificationTitle = "✅ Order Confirmed!";
        notificationBody = `Your order for ${afterData.product_name} has been confirmed by ${afterData.seller_name}`;
        break;
      case "in_transit":
        notificationTitle = "🚚 Order In Transit!";
        notificationBody = `Your order for ${afterData.product_name} is on the way`;
        break;
      case "delivered":
        notificationTitle = "📦 Order Delivered!";
        notificationBody = `Your order for ${afterData.product_name} has been delivered`;
        break;
      case "completed":
        notificationTitle = "🎉 Order Completed!";
        notificationBody = `Thank you for confirming receipt of ${afterData.product_name}`;
        break;
      case "cancelled":
        notificationTitle = "❌ Order Cancelled";
        notificationBody = `Your order for ${afterData.product_name} has been cancelled`;
        break;
      default:
        // Don't send notification for other status changes
        return;
    }

    // Get buyer's FCM token
    const buyerFCMToken = await getUserFCMToken(afterData.buyer_id);

    if (buyerFCMToken) {
      // Send FCM push notification
      await sendFCMNotification(
          buyerFCMToken,
          notificationTitle,
          notificationBody,
          {
            type: "order",
            order_id: orderId,
            status: newStatus,
            action_url: `/orders/${orderId}`,
          },
      );
    }

    // Create in-app notification
    await createInAppNotification(
        afterData.buyer_id,
        "order",
        notificationTitle,
        notificationBody,
        `/orders/${orderId}`,
        {order_id: orderId, status: newStatus},
    );

    logger.info(`✅ Order status notification sent to buyer: ${afterData.buyer_id}`);
  } catch (error) {
    logger.error("❌ Error sending order status notification:", error);
  }
});

// ============================================================================
// CLOUD FUNCTIONS - MESSAGE NOTIFICATIONS
// ============================================================================

/**
 * Trigger: New message created
 * Action: Notify recipient about new message
 */
exports.onNewMessage = onDocumentCreated("messages/{messageId}", async (event) => {
  const message = event.data.data();
  const messageId = event.params.messageId;

  logger.info(`💬 New message created: ${messageId}`);
  logger.info(`   From: ${message.sender_name}`);
  logger.info(`   To: ${message.recipient_id}`);

  try {
    // Get recipient's FCM token
    const recipientFCMToken = await getUserFCMToken(message.recipient_id);

    if (!recipientFCMToken) {
      logger.warn(`Cannot send FCM - No token for recipient: ${message.recipient_id}`);
      // Still create in-app notification
      await createInAppNotification(
          message.recipient_id,
          "message",
          `💬 ${message.sender_name}`,
          message.message || "Sent you a message",
          `/messages/${message.sender_id}`,
          {
            sender_id: message.sender_id,
            sender_name: message.sender_name,
          },
      );
      return;
    }

    // Send FCM push notification
    await sendFCMNotification(
        recipientFCMToken,
        `💬 ${message.sender_name}`,
        message.message || "Sent you a message",
        {
          type: "message",
          sender_id: message.sender_id,
          sender_name: message.sender_name,
          action_url: `/messages/${message.sender_id}`,
        },
    );

    // Also create in-app notification
    await createInAppNotification(
        message.recipient_id,
        "message",
        `💬 ${message.sender_name}`,
        message.message || "Sent you a message",
        `/messages/${message.sender_id}`,
        {
          sender_id: message.sender_id,
          sender_name: message.sender_name,
        },
    );

    logger.info(`✅ Message notification sent to: ${message.recipient_id}`);
  } catch (error) {
    logger.error("❌ Error sending message notification:", error);
  }
});

// ============================================================================
// CLOUD FUNCTIONS - PSA VERIFICATION NOTIFICATIONS
// ============================================================================

/**
 * Trigger: PSA verification submitted
 * Action: Notify admin about new PSA verification
 */
exports.onPSAVerificationSubmitted = onDocumentCreated("psa_verifications/{verificationId}", async (event) => {
  const verification = event.data.data();
  const verificationId = event.params.verificationId;

  logger.info(`📋 PSA verification submitted: ${verificationId}`);
  logger.info(`   PSA: ${verification.psa_name}`);
  logger.info(`   Status: ${verification.status}`);

  // Only notify admin for new submissions (pending status)
  if (verification.status !== "pending") {
    return;
  }

  try {
    // Get admin user FCM token
    // Note: You need to create an admin user with a known ID
    const ADMIN_USER_ID = "ADMIN"; // Replace with actual admin user ID

    const adminFCMToken = await getUserFCMToken(ADMIN_USER_ID);

    if (!adminFCMToken) {
      logger.warn(`Cannot send FCM - No token for admin: ${ADMIN_USER_ID}`);
      // Still create in-app notification
      await createInAppNotification(
          ADMIN_USER_ID,
          "alert",
          "🆕 New PSA Verification",
          `${verification.psa_name} submitted verification documents`,
          "/admin/psa-verification",
          {verification_id: verificationId},
      );
      return;
    }

    // Send FCM push notification
    await sendFCMNotification(
        adminFCMToken,
        "🆕 New PSA Verification",
        `${verification.psa_name} submitted verification documents for review`,
        {
          type: "psa_verification",
          verification_id: verificationId,
          psa_name: verification.psa_name,
          action_url: "/admin/psa-verification",
        },
    );

    // Also create in-app notification
    await createInAppNotification(
        ADMIN_USER_ID,
        "alert",
        "🆕 New PSA Verification",
        `${verification.psa_name} submitted verification documents`,
        "/admin/psa-verification",
        {verification_id: verificationId},
    );

    logger.info(`✅ PSA verification notification sent to admin`);
  } catch (error) {
    logger.error("❌ Error sending PSA verification notification:", error);
  }
});

/**
 * Trigger: PSA verification status updated
 * Action: Notify PSA about approval/rejection
 */
exports.onPSAVerificationStatusUpdate = onDocumentUpdated("psa_verifications/{verificationId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const verificationId = event.params.verificationId;

  // Only trigger if status changed
  if (beforeData.status === afterData.status) {
    return;
  }

  const newStatus = afterData.status;
  logger.info(`📋 PSA verification status updated: ${verificationId} → ${newStatus}`);

  // Only notify PSA for approved/rejected status
  if (newStatus !== "approved" && newStatus !== "rejected") {
    return;
  }

  try {
    let notificationTitle = "";
    let notificationBody = "";

    if (newStatus === "approved") {
      notificationTitle = "✅ PSA Verification Approved!";
      notificationBody = "Congratulations! Your PSA verification has been approved.";
    } else if (newStatus === "rejected") {
      notificationTitle = "❌ PSA Verification Rejected";
      notificationBody = afterData.rejection_reason || "Your PSA verification was not approved. Please review and resubmit.";
    }

    // Get PSA's FCM token
    const psaFCMToken = await getUserFCMToken(afterData.psa_id);

    if (psaFCMToken) {
      // Send FCM push notification
      await sendFCMNotification(
          psaFCMToken,
          notificationTitle,
          notificationBody,
          {
            type: "psa_verification",
            verification_id: verificationId,
            status: newStatus,
            action_url: "/psa/verification",
          },
      );
    }

    // Create in-app notification
    await createInAppNotification(
        afterData.psa_id,
        "alert",
        notificationTitle,
        notificationBody,
        "/psa/verification",
        {verification_id: verificationId, status: newStatus},
    );

    logger.info(`✅ PSA verification status notification sent to: ${afterData.psa_id}`);
  } catch (error) {
    logger.error("❌ Error sending PSA verification status notification:", error);
  }
});

// ============================================================================
// CLOUD FUNCTIONS - LOW STOCK ALERTS
// ============================================================================

/**
 * Trigger: Product stock quantity updated
 * Action: Notify seller if stock is low (below 10 units)
 */
exports.onLowStockAlert = onDocumentUpdated("products/{productId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const productId = event.params.productId;

  // Check if stock decreased and is now low
  const LOW_STOCK_THRESHOLD = 10;
  const stockDecreased = afterData.stock_quantity < beforeData.stock_quantity;
  const isLowStock = afterData.stock_quantity <= LOW_STOCK_THRESHOLD;
  const wasNotLowStock = beforeData.stock_quantity > LOW_STOCK_THRESHOLD;

  // Only send alert if stock just became low
  if (!stockDecreased || !isLowStock || !wasNotLowStock) {
    return;
  }

  logger.info(`⚠️ Low stock alert: ${productId}`);
  logger.info(`   Product: ${afterData.name}`);
  logger.info(`   Stock: ${afterData.stock_quantity} ${afterData.unit}`);
  logger.info(`   Seller: ${afterData.seller_id}`);

  try {
    // Get seller's FCM token
    const sellerFCMToken = await getUserFCMToken(afterData.seller_id);

    if (sellerFCMToken) {
      // Send FCM push notification
      await sendFCMNotification(
          sellerFCMToken,
          "⚠️ Low Stock Alert",
          `${afterData.name} is running low (${afterData.stock_quantity} ${afterData.unit} remaining)`,
          {
            type: "stock_alert",
            product_id: productId,
            product_name: afterData.name,
            stock_quantity: afterData.stock_quantity,
            action_url: `/products/edit/${productId}`,
          },
      );
    }

    // Create in-app notification
    await createInAppNotification(
        afterData.seller_id,
        "alert",
        "⚠️ Low Stock Alert",
        `${afterData.name} is running low (${afterData.stock_quantity} ${afterData.unit} remaining)`,
        `/products/edit/${productId}`,
        {
          product_id: productId,
          product_name: afterData.name,
          stock_quantity: afterData.stock_quantity,
        },
    );

    logger.info(`✅ Low stock alert sent to seller: ${afterData.seller_id}`);
  } catch (error) {
    logger.error("❌ Error sending low stock alert:", error);
  }
});

// ============================================================================
// CLOUD FUNCTIONS - RECEIPT NOTIFICATIONS
// ============================================================================

/**
 * Trigger: Receipt generated after delivery confirmation
 * Action: Notify buyer that receipt is ready
 */
exports.onReceiptGenerated = onDocumentCreated("receipts/{receiptId}", async (event) => {
  const receipt = event.data.data();
  const receiptId = event.params.receiptId;

  logger.info(`🧾 Receipt generated: ${receiptId}`);
  logger.info(`   Order ID: ${receipt.order_id}`);
  logger.info(`   Buyer: ${receipt.buyer_id}`);

  try {
    // Get buyer's FCM token
    const buyerFCMToken = await getUserFCMToken(receipt.buyer_id);

    if (buyerFCMToken) {
      // Send FCM push notification
      await sendFCMNotification(
          buyerFCMToken,
          "🧾 Receipt Ready",
          `Your receipt for ${receipt.items.length} item(s) is ready to view`,
          {
            type: "receipt",
            receipt_id: receiptId,
            order_id: receipt.order_id,
            action_url: `/receipts/${receiptId}`,
          },
      );
    }

    // Create in-app notification
    await createInAppNotification(
        receipt.buyer_id,
        "order",
        "🧾 Receipt Ready",
        `Your receipt for ${receipt.items.length} item(s) is ready to view`,
        `/receipts/${receiptId}`,
        {receipt_id: receiptId, order_id: receipt.order_id},
    );

    logger.info(`✅ Receipt notification sent to buyer: ${receipt.buyer_id}`);
  } catch (error) {
    logger.error("❌ Error sending receipt notification:", error);
  }
});

// ============================================================================
// CLOUD FUNCTIONS - DELIVERY TRACKING NOTIFICATIONS
// ============================================================================

/**
 * Trigger: Delivery tracking created
 * Action: Notify buyer that tracking is available
 */
exports.onDeliveryTrackingCreated = onDocumentCreated("delivery_tracking/{trackingId}", async (event) => {
  const tracking = event.data.data();
  const trackingId = event.params.trackingId;

  logger.info(`📦 Delivery tracking created: ${trackingId}`);
  logger.info(`   Order ID: ${tracking.order_id}`);
  logger.info(`   Recipient: ${tracking.recipient_id}`);

  try {
    // Get recipient's FCM token
    const recipientFCMToken = await getUserFCMToken(tracking.recipient_id);

    if (recipientFCMToken) {
      // Send FCM push notification
      await sendFCMNotification(
          recipientFCMToken,
          "📦 Delivery Tracking Available",
          `Track your order from ${tracking.delivery_person_name}`,
          {
            type: "delivery_tracking",
            tracking_id: trackingId,
            order_id: tracking.order_id,
            action_url: `/track-delivery/${trackingId}`,
          },
      );
    }

    // Create in-app notification
    await createInAppNotification(
        tracking.recipient_id,
        "delivery",
        "📦 Delivery Tracking Available",
        `Track your order from ${tracking.delivery_person_name}`,
        `/track-delivery/${trackingId}`,
        {tracking_id: trackingId, order_id: tracking.order_id},
    );

    logger.info(`✅ Delivery tracking notification sent to recipient: ${tracking.recipient_id}`);
  } catch (error) {
    logger.error("❌ Error sending delivery tracking notification:", error);
  }
});

/**
 * Trigger: Delivery status updated
 * Action: Notify buyer on delivery progress (started, in progress, completed)
 */
exports.onDeliveryStatusUpdate = onDocumentUpdated("delivery_tracking/{trackingId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const trackingId = event.params.trackingId;

  // Check if status changed
  if (beforeData.status === afterData.status) {
    logger.info(`Delivery ${trackingId}: status unchanged, skipping notification`);
    return;
  }

  logger.info(`🚚 Delivery status changed: ${beforeData.status} → ${afterData.status}`);
  logger.info(`   Tracking ID: ${trackingId}`);
  logger.info(`   Recipient: ${afterData.recipient_id}`);

  try {
    let notificationTitle = "";
    let notificationBody = "";
    let notificationType = "delivery";

    // Determine notification content based on status
    switch (afterData.status) {
      case "confirmed":
        notificationTitle = "✅ Delivery Confirmed";
        notificationBody = `${afterData.delivery_person_name} confirmed your delivery`;
        break;

      case "inProgress":
        notificationTitle = "🚚 Delivery Started";
        notificationBody = `${afterData.delivery_person_name} is on the way with your order`;
        break;

      case "completed":
        notificationTitle = "✅ Delivery Completed";
        notificationBody = `Your order from ${afterData.delivery_person_name} has been delivered`;
        notificationType = "success";
        break;

      case "cancelled":
        notificationTitle = "❌ Delivery Cancelled";
        notificationBody = `Delivery from ${afterData.delivery_person_name} was cancelled`;
        notificationType = "alert";
        break;

      case "failed":
        notificationTitle = "⚠️ Delivery Failed";
        notificationBody = `Delivery from ${afterData.delivery_person_name} could not be completed`;
        notificationType = "alert";
        break;

      default:
        logger.info(`Unknown delivery status: ${afterData.status}, skipping notification`);
        return;
    }

    // Get recipient's FCM token
    const recipientFCMToken = await getUserFCMToken(afterData.recipient_id);

    if (recipientFCMToken) {
      // Send FCM push notification
      await sendFCMNotification(
          recipientFCMToken,
          notificationTitle,
          notificationBody,
          {
            type: notificationType,
            tracking_id: trackingId,
            order_id: afterData.order_id,
            delivery_status: afterData.status,
            action_url: afterData.status === "inProgress" ?
              `/track-delivery/${trackingId}` :
              `/orders/${afterData.order_id}`,
          },
      );
    }

    // Create in-app notification
    await createInAppNotification(
        afterData.recipient_id,
        notificationType,
        notificationTitle,
        notificationBody,
        afterData.status === "inProgress" ?
          `/track-delivery/${trackingId}` :
          `/orders/${afterData.order_id}`,
        {
          tracking_id: trackingId,
          order_id: afterData.order_id,
          delivery_status: afterData.status,
        },
    );

    logger.info(`✅ Delivery status notification sent to recipient: ${afterData.recipient_id}`);
  } catch (error) {
    logger.error("❌ Error sending delivery status notification:", error);
  }
});

// ============================================================================
// EXPORTS
// ============================================================================

logger.info("✅ Firebase Cloud Functions loaded successfully");
logger.info("📋 Registered functions:");
logger.info("   - onNewOrder");
logger.info("   - onOrderStatusUpdate");
logger.info("   - onNewMessage");
logger.info("   - onPSAVerificationSubmitted");
logger.info("   - onPSAVerificationStatusUpdate");
logger.info("   - onLowStockAlert");
logger.info("   - onReceiptGenerated");
logger.info("   - onDeliveryTrackingCreated");
logger.info("   - onDeliveryStatusUpdate");
