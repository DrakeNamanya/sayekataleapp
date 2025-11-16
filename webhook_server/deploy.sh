#!/bin/bash

# PawaPay Webhook Server - Cloud Run Deployment Script
# This script automates the deployment process

set -e  # Exit on error

echo "🚀 PawaPay Webhook Deployment Script"
echo "===================================="
echo ""

# Configuration
PROJECT_ID="sayekataleapp"
SERVICE_NAME="pawapay-webhook"
REGION="us-central1"
PAWAPAY_TOKEN="eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc4NTA5MjM2LCJpYXQiOjE3NjI5NzY0MzYsInBtIjoiREFGLFBBRiIsImp0aSI6ImE0NjQyZjUyLWYwODYtNGJjNy1hMGY3LTQ2MmJiNDgyYzM1MSJ9.zyFdgBTQ-dj_NiR15ChPjLM6kYjH3ZB4J9G8ye4TKiOjPgdXsJ53U08-WspwZ8JtjXua8FGuIf4VhQVcmVRjHQ"

# Add gcloud to PATH
export PATH="/home/user/google-cloud-sdk/bin:$PATH"

# Step 1: Check authentication
echo "📋 Step 1: Checking authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Not authenticated. Please run: gcloud auth login"
    exit 1
fi
echo "✅ Authenticated"
echo ""

# Step 2: Set project
echo "📋 Step 2: Setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID
echo "✅ Project set"
echo ""

# Step 3: Enable required APIs
echo "📋 Step 3: Enabling required APIs..."
echo "   - Cloud Run API"
gcloud services enable run.googleapis.com --quiet

echo "   - Cloud Build API"
gcloud services enable cloudbuild.googleapis.com --quiet

echo "   - Artifact Registry API"
gcloud services enable artifactregistry.googleapis.com --quiet

echo "✅ APIs enabled"
echo ""

# Step 4: Deploy to Cloud Run
echo "📋 Step 4: Deploying to Cloud Run..."
echo "   Region: $REGION"
echo "   Service: $SERVICE_NAME"
echo ""

cd /home/user/flutter_app/webhook_server

gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 10 \
  --set-env-vars "PAWAPAY_API_TOKEN=$PAWAPAY_TOKEN" \
  --quiet

echo ""
echo "✅ Deployment complete!"
echo ""

# Step 5: Get service URL
echo "📋 Step 5: Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format='value(status.url)')
echo ""
echo "🎉 SUCCESS! Your webhook is deployed!"
echo "=================================="
echo ""
echo "📍 Service URL: $SERVICE_URL"
echo ""
echo "🔗 Webhook endpoints:"
echo "   - Health check: $SERVICE_URL/health"
echo "   - PawaPay webhook: $SERVICE_URL/api/pawapay/webhook"
echo ""
echo "⚠️  NEXT STEPS:"
echo ""
echo "1. Test health endpoint:"
echo "   curl $SERVICE_URL/health"
echo ""
echo "2. Configure PawaPay Dashboard:"
echo "   - Go to: https://dashboard.pawapay.io/"
echo "   - Settings → Webhooks"
echo "   - Add URL: $SERVICE_URL/api/pawapay/webhook"
echo ""
echo "3. Save these URLs for APK build:"
echo "   API_BASE_URL=$SERVICE_URL"
echo "   PAWAPAY_CALLBACK=$SERVICE_URL/api/pawapay/webhook"
echo ""
echo "4. View logs:"
echo "   gcloud run services logs read $SERVICE_NAME --region $REGION --follow"
echo ""
echo "📝 Full documentation: webhook_server/DEPLOYMENT_GUIDE.md"
echo ""
