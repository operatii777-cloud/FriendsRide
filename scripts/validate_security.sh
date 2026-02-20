#!/bin/bash

# 🔐 FriendsRide Security Validation Script
# Validează că toate API keys-urile sunt configurate corect

set -e

echo "🔐 Validating FriendsRide Security Configuration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required environment variables are set
MISSING_VARS=()

# OpenAI
if [ -z "$OPENAI_API_KEY" ]; then
    MISSING_VARS+=("OPENAI_API_KEY")
fi

# Firebase
if [ -z "$FIREBASE_API_KEY" ]; then
    MISSING_VARS+=("FIREBASE_API_KEY")
fi

# Mapbox
if [ -z "$MAPBOX_PUBLIC_TOKEN" ]; then
    MISSING_VARS+=("MAPBOX_PUBLIC_TOKEN")
fi

if [ -z "$MAPBOX_SECRET_TOKEN" ]; then
    MISSING_VARS+=("MAPBOX_SECRET_TOKEN")
fi

if [ -z "$MAPBOX_ACCESS_TOKEN" ]; then
    MISSING_VARS+=("MAPBOX_ACCESS_TOKEN")
fi

# SDK Registry
if [ -z "$SDK_REGISTRY_TOKEN" ]; then
    MISSING_VARS+=("SDK_REGISTRY_TOKEN")
fi

# Report results
if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All required API keys are configured${NC}"
    echo "🔐 Security validation passed"
    exit 0
else
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "   ${RED}- $var${NC}"
    done
    
    echo ""
    echo -e "${YELLOW}📋 To fix this:${NC}"
    echo "1. Set the missing environment variables in your CI/CD pipeline"
    echo "2. For local development, create a .env file with:"
    echo "   OPENAI_API_KEY=your_key_here"
    echo "   FIREBASE_API_KEY=your_key_here"
    echo "   MAPBOX_PUBLIC_TOKEN=your_token_here"
    echo "   MAPBOX_SECRET_TOKEN=your_secret_here"
    echo "   MAPBOX_ACCESS_TOKEN=your_token_here"
    echo "   SDK_REGISTRY_TOKEN=your_sdk_token_here"
    echo ""
    echo "3. Or use --dart-define when running Flutter:"
    echo "   flutter run --dart-define=OPENAI_API_KEY=your_key"
    
    exit 1
fi
