# Firebase Cloud Functions - SayeKatale App

## Overview

This directory contains Firebase Cloud Functions that enable **real-time push notifications** for the SayeKatale app.

## Functions

| Function | Trigger | Action |
|----------|---------|--------|
| `onNewOrder` | New order created | Notify seller (SME/PSA) |
| `onOrderStatusUpdate` | Order status changes | Notify buyer (SHG) |
| `onNewMessage` | New message sent | Notify recipient |
| `onPSAVerificationSubmitted` | PSA submits verification | Notify admin |
| `onPSAVerificationStatusUpdate` | PSA approved/rejected | Notify PSA |
| `onLowStockAlert` | Stock drops below 10 | Notify seller |
| `onReceiptGenerated` | Receipt created | Notify buyer |

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Deploy Functions
```bash
cd /home/user/flutter_app
firebase deploy --only functions
```

Or use the deployment script:
```bash
cd /home/user/flutter_app
./deploy_functions.sh
```

## Testing

### Test a Function Locally
```bash
# Start Firebase emulators
firebase emulators:start

# In another terminal, trigger test data
# (Create documents in Firestore to trigger functions)
```

### View Logs
```bash
# View all function logs
firebase functions:log

# View specific function
firebase functions:log --only onNewOrder

# Stream real-time logs
firebase functions:log --follow
```

## Configuration

### Admin User ID
Update the admin user ID in `index.js` (line ~351):
```javascript
const ADMIN_USER_ID = "YOUR_ADMIN_UID_HERE";
```

Get admin UID from:
- Firebase Console → Authentication → Find admin user → Copy UID

## Documentation

- **Deployment Guide**: `/home/user/flutter_app/FIREBASE_FUNCTIONS_DEPLOYMENT_GUIDE.md`
- **FCM Implementation**: `/home/user/flutter_app/FCM_IMPLEMENTATION_GUIDE.md`

## Dependencies

- `firebase-functions`: ^4.9.0
- `firebase-admin`: ^13.0.1

## Node.js Version

- Node.js 20 (as specified in `package.json`)

## Support

For issues or questions, see the comprehensive deployment guide.
