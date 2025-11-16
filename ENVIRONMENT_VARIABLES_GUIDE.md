# 🔐 Environment Variables Guide for SayeKatale App

## Overview
This guide explains how to work with environment variables in the SayeKatale Flutter application for secure configuration management.

## Why Environment Variables?

### Security Benefits
- ✅ **No Hardcoded Secrets**: API tokens and keys are not committed to source control
- ✅ **Per-Environment Config**: Different settings for development, staging, and production
- ✅ **Team Security**: Each developer uses their own API credentials
- ✅ **Easy Rotation**: Change secrets without modifying code

### Previous Security Issue (FIXED)
```dart
// ❌ BEFORE - Hardcoded token exposed in source code
static const String apiToken = 'eyJraWQiOiIxIiwiYWxn...';

// ✅ AFTER - Token loaded from environment variable
static String get apiToken => Environment.pawaPayToken;
```

## Quick Start

### For Development

#### Step 1: Get Your Development Credentials
- **PawaPay Sandbox Token**: Get from https://dashboard.pawapay.co.uk/ (use sandbox environment)
- **Firebase Config**: Use development Firebase project

#### Step 2: Run with Environment Variables
```bash
# Simple development run
flutter run \
  --dart-define=PRODUCTION=false \
  --dart-define=PAWAPAY_API_TOKEN=your_sandbox_token_here \
  --dart-define=API_BASE_URL=https://dev-api.sayekatale.com

# With all variables
flutter run \
  --dart-define=PRODUCTION=false \
  --dart-define=DEBUG_MODE=true \
  --dart-define=PAWAPAY_API_TOKEN=your_sandbox_token \
  --dart-define=PAWAPAY_DEPOSIT_CALLBACK=https://your-ngrok-url.ngrok.io/webhooks/deposit \
  --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=https://your-ngrok-url.ngrok.io/webhooks/withdrawal
```

#### Step 3: Test the Configuration
When you run the app, you should see in the console:
```
========================================
🔧 SayeKatale App Initialization
========================================
✅ Environment validation passed
========================================
Environment Configuration
========================================
Environment: Development
Debug Mode: true
PawaPay Enabled: true
PawaPay Token Set: Yes
========================================
```

### For Production Builds

#### Build APK with Production Credentials
```bash
flutter build apk --release \
  --dart-define=PRODUCTION=true \
  --dart-define=PAWAPAY_API_TOKEN=$PRODUCTION_PAWAPAY_TOKEN \
  --dart-define=PAWAPAY_DEPOSIT_CALLBACK=https://api.sayekatale.com/webhooks/pawapay/deposit \
  --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=https://api.sayekatale.com/webhooks/pawapay/withdrawal \
  --dart-define=API_BASE_URL=https://api.sayekatale.com \
  --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY
```

#### Build App Bundle (AAB) for Play Store
```bash
flutter build appbundle --release \
  --dart-define=PRODUCTION=true \
  --dart-define=PAWAPAY_API_TOKEN=$PRODUCTION_PAWAPAY_TOKEN \
  --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY
  # ... other variables
```

## Available Environment Variables

### Core App Settings
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PRODUCTION` | boolean | false | Production mode flag |
| `DEBUG_MODE` | boolean | true | Enable debug logging |
| `APP_VERSION` | string | 1.0.0 | App version number |

### API Configuration
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `API_BASE_URL` | string | https://api.sayekatale.com | Backend API base URL |
| `API_TIMEOUT` | int | 30000 | API request timeout (ms) |

### PawaPay Integration
| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `PAWAPAY_API_TOKEN` | string | ✅ Yes | PawaPay API authentication token |
| `PAWAPAY_DEPOSIT_CALLBACK` | string | ✅ Yes | Deposit webhook URL |
| `PAWAPAY_WITHDRAWAL_CALLBACK` | string | ✅ Yes | Withdrawal webhook URL |

### Firebase Configuration
| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `FIREBASE_PROJECT_ID` | string | No | Firebase project ID |
| `FIREBASE_API_KEY` | string | ⚠️ Prod only | Firebase API key |
| `FIREBASE_AUTH_DOMAIN` | string | No | Firebase auth domain |
| `FIREBASE_STORAGE_BUCKET` | string | No | Storage bucket name |
| `FIREBASE_MESSAGING_SENDER_ID` | string | ⚠️ Prod only | FCM sender ID |

### Feature Flags
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ENABLE_PAWAPAY` | boolean | true | Enable mobile money integration |
| `ENABLE_ANALYTICS` | boolean | true | Enable Firebase Analytics |
| `ENABLE_CRASHLYTICS` | boolean | true | Enable crash reporting |
| `ENABLE_PERFORMANCE_MONITORING` | boolean | true | Enable performance tracking |

## Using Environment Variables in Code

### Import Environment Class
```dart
import 'config/environment.dart';
```

### Access Variables
```dart
// Check if production
if (Environment.isProduction) {
  // Production-specific code
}

// Get API token
final token = Environment.pawaPayToken;

// Get API base URL
final apiUrl = Environment.apiBaseUrl;

// Check feature flags
if (Environment.enablePawaPay) {
  // Initialize PawaPay service
}
```

### Validate Environment
```dart
void main() async {
  try {
    Environment.validateEnvironment();
    print('✅ Environment validation passed');
  } catch (e) {
    print('❌ Environment validation failed: $e');
    // In production, this will throw and prevent app startup
  }
}
```

### Debug Configuration
```dart
// Print all environment values (debug mode only)
Environment.printConfig();
```

## Development Workflows

### Local Development with Webhook Testing

#### Setup ngrok for Local Webhooks
```bash
# Install ngrok: https://ngrok.com/download
# Start local webhook server
cd /home/user/webhook_server
python3 webhook_server.py

# In another terminal, expose webhook server
ngrok http 8080

# Copy the ngrok URL (e.g., https://abc123.ngrok.io)
```

#### Run Flutter App with ngrok URL
```bash
flutter run \
  --dart-define=PRODUCTION=false \
  --dart-define=PAWAPAY_API_TOKEN=sandbox_token \
  --dart-define=PAWAPAY_DEPOSIT_CALLBACK=https://abc123.ngrok.io/webhooks/pawapay/deposit \
  --dart-define=PAWAPAY_WITHDRAWAL_CALLBACK=https://abc123.ngrok.io/webhooks/pawapay/withdrawal
```

### Testing Different Environments

#### Development Environment
```bash
flutter run \
  --dart-define=PRODUCTION=false \
  --dart-define=API_BASE_URL=https://dev-api.sayekatale.com \
  --dart-define=PAWAPAY_API_TOKEN=dev_token
```

#### Staging Environment
```bash
flutter run \
  --dart-define=PRODUCTION=false \
  --dart-define=API_BASE_URL=https://staging-api.sayekatale.com \
  --dart-define=PAWAPAY_API_TOKEN=staging_token
```

#### Production Environment (Testing Only)
```bash
# ⚠️ BE CAREFUL - Uses real production data!
flutter run \
  --dart-define=PRODUCTION=true \
  --dart-define=API_BASE_URL=https://api.sayekatale.com \
  --dart-define=PAWAPAY_API_TOKEN=$PROD_TOKEN
```

## Security Best Practices

### DO ✅
1. **Use different tokens** for dev, staging, and production
2. **Store production tokens** in GitHub Secrets, not locally
3. **Add .env files to .gitignore** (already configured)
4. **Rotate tokens regularly** (every 90 days recommended)
5. **Test with sandbox credentials** during development
6. **Validate environment** on app startup
7. **Use feature flags** to disable features in specific environments

### DON'T ❌
1. **Don't commit real tokens** to git
2. **Don't share production tokens** in Slack/Email/Discord
3. **Don't use production tokens** for local development
4. **Don't hard-code any secrets** in source code
5. **Don't expose tokens** in error messages or logs
6. **Don't store tokens** in plain text files
7. **Don't reuse tokens** across multiple projects

## Troubleshooting

### App Fails to Start with "PAWAPAY_API_TOKEN must be set"
**Problem**: Running production build without required environment variables

**Solution**:
```bash
# Make sure PRODUCTION=true builds include all required variables
flutter build apk --release \
  --dart-define=PRODUCTION=true \
  --dart-define=PAWAPAY_API_TOKEN=your_token
```

### PawaPay API Returns 401 Unauthorized
**Problem**: Wrong or expired API token

**Solutions**:
1. Check token is correct: `echo $PAWAPAY_API_TOKEN`
2. Verify token in PawaPay dashboard
3. Try regenerating token from dashboard
4. Ensure no extra spaces in token string

### Webhooks Not Receiving Callbacks
**Problem**: PawaPay can't reach your webhook server

**Solutions**:
1. Check ngrok is running: `curl https://your-url.ngrok.io`
2. Verify callback URLs in app match PawaPay dashboard
3. Check webhook server logs for errors
4. Test webhook manually with curl:
```bash
curl -X POST https://your-url.ngrok.io/webhooks/pawapay/deposit \
  -H "Content-Type: application/json" \
  -d '{"status": "COMPLETED"}'
```

### Environment Values Not Taking Effect
**Problem**: Old values cached or not passed correctly

**Solutions**:
1. Clean build cache: `flutter clean && flutter pub get`
2. Verify variables in console output at startup
3. Check spelling of variable names (case-sensitive)
4. Ensure using `--dart-define` not `-D` or `--define`

### Firebase Configuration Errors
**Problem**: Firebase not initialized properly

**Solutions**:
1. Check firebase_options.dart exists
2. Verify google-services.json is in android/app/
3. For Web platform, ensure firebase_options.dart has Web config
4. Check Firebase project ID matches in all configs

## CI/CD Integration

### GitHub Actions
Environment variables are configured as GitHub Secrets and automatically injected during builds.

See: `.github/workflows/deploy-production.yml`

### Required GitHub Secrets
```yaml
PAWAPAY_API_TOKEN           # Production PawaPay token
PAWAPAY_DEPOSIT_CALLBACK    # Production webhook URL
PAWAPAY_WITHDRAWAL_CALLBACK # Production webhook URL
FIREBASE_API_KEY            # Firebase API key
FIREBASE_MESSAGING_SENDER_ID # FCM sender ID
ANDROID_KEYSTORE_BASE64     # Base64-encoded keystore
# ... see IMPLEMENTATION_GUIDE.md for full list
```

## Getting Help

### Documentation
- See `.env.example` for all available variables
- See `IMPLEMENTATION_GUIDE.md` for deployment instructions
- See `PRODUCTION_DEPLOYMENT_PLAN.md` for security details

### Support Contacts
- **Technical Issues**: Open GitHub issue
- **PawaPay API**: support@pawapay.co.uk
- **Firebase**: Firebase Console support chat

## Quick Reference Card

### Development Run
```bash
flutter run --dart-define=PRODUCTION=false --dart-define=PAWAPAY_API_TOKEN=dev_token
```

### Production Build
```bash
flutter build apk --release --dart-define=PRODUCTION=true --dart-define=PAWAPAY_API_TOKEN=$PROD_TOKEN
```

### Check Configuration
```dart
Environment.printConfig();  // Prints all environment values
```

### Validate Environment
```dart
Environment.validateEnvironment();  // Throws if invalid
```

---

**Last Updated**: Phase 1 - Security Hardening
**Author**: Development Team
**Status**: Ready for use
