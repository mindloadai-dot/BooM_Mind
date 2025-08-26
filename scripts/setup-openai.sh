#!/bin/bash

# OpenAI API Key Setup Script for Mindload
# This script sets up the OpenAI API key in Firebase Secret Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 OpenAI API Key Setup for Mindload${NC}"
echo "=================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Google Cloud CLI (gcloud) is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠️  Not authenticated with Google Cloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ No project ID configured${NC}"
    echo "Please run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo -e "${GREEN}✅ Using project: $PROJECT_ID${NC}"

# OpenAI API Key (you can modify this or set as environment variable)
OPENAI_API_KEY="${OPENAI_API_KEY:-YOUR_OPENAI_API_KEY_HERE}"

echo -e "${BLUE}🔑 Setting up OpenAI API Key...${NC}"

# Create the secret
echo "Creating OpenAI API Key secret..."
echo "$OPENAI_API_KEY" | gcloud secrets create OPENAI_API_KEY \
    --data-file=- \
    --replication-policy="automatic" \
    --project="$PROJECT_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ OpenAI API Key secret created successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Secret might already exist, checking...${NC}"
    
    # Check if secret exists
    if gcloud secrets describe OPENAI_API_KEY --project="$PROJECT_ID" &>/dev/null; then
        echo -e "${GREEN}✅ OpenAI API Key secret already exists${NC}"
        
        # Update the existing secret
        echo "Updating existing secret..."
        echo "$OPENAI_API_KEY" | gcloud secrets versions add OPENAI_API_KEY \
            --data-file=- \
            --project="$PROJECT_ID"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ OpenAI API Key secret updated successfully${NC}"
        else
            echo -e "${RED}❌ Failed to update secret${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to create secret${NC}"
        exit 1
    fi
fi

# Grant access to Cloud Functions service account
echo -e "${BLUE}🔐 Granting access to Cloud Functions...${NC}"

# Get the Cloud Functions service account
SERVICE_ACCOUNT="${PROJECT_ID}@appspot.gserviceaccount.com"

echo "Granting access to: $SERVICE_ACCOUNT"

gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/secretmanager.secretAccessor" \
    --project="$PROJECT_ID"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Access granted to Cloud Functions${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to grant access (might already have access)${NC}"
fi

# Set environment variable for Cloud Functions
echo -e "${BLUE}🌍 Setting environment variable for Cloud Functions...${NC}"

# Deploy a simple function to set the environment variable
echo "Setting environment variable in Cloud Functions..."

# Create a temporary function configuration
cat > /tmp/function-config.yaml << EOF
runtime: nodejs20
region: us-central1
environmentVariables:
  OPENAI_API_KEY: "\${OPENAI_API_KEY}"
EOF

# Update the function configuration
gcloud functions deploy ai-processing \
    --gen2 \
    --runtime=nodejs20 \
    --region=us-central1 \
    --source=functions/src \
    --entry-point=generateFlashcards \
    --trigger-http \
    --allow-unauthenticated \
    --set-env-vars="OPENAI_API_KEY=\${OPENAI_API_KEY}" \
    --project="$PROJECT_ID" \
    --quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Cloud Functions environment variable set${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to set environment variable (function might not exist yet)${NC}"
fi

# Clean up
rm -f /tmp/function-config.yaml

echo ""
echo -e "${GREEN}🎉 OpenAI API Key setup completed!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "1. Deploy your Cloud Functions: firebase deploy --only functions"
echo "2. Test the AI features in your app"
echo "3. Monitor usage in OpenAI dashboard"
echo ""
echo -e "${BLUE}🔍 Verification:${NC}"
echo "You can verify the secret was created by running:"
echo "gcloud secrets list --project=$PROJECT_ID"
echo ""
echo -e "${BLUE}⚠️  Security Note:${NC}"
echo "The API key is now stored securely in Firebase Secret Manager"
echo "and accessed only by your Cloud Functions, not by client code."
echo ""
echo -e "${GREEN}✅ Setup complete! Your Mindload app can now use AI features.${NC}"
