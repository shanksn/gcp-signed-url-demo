#!/bin/bash

# Interactive demo to view signed URLs and resumable URLs

set -e

API_URL="https://biotechproject-483505.uc.r.appspot.com"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║           Signed URL & Resumable URL Demo                     ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This demo will show you how signed URLs work step-by-step."
echo ""

# Wait for user
read -p "Press Enter to continue..."
echo ""

# ==========================================
# PART 1: STANDARD SIGNED URL
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PART 1: Standard Signed URL (PUT Method)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Step 1: Requesting a signed URL from backend..."
echo ""

RESPONSE=$(curl -s -X POST "${API_URL}/api/generate-signed-url" \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "demo-file.txt",
    "content_type": "text/plain"
  }')

echo "✅ Response from backend:"
echo "$RESPONSE" | jq .
echo ""

SIGNED_URL=$(echo "$RESPONSE" | jq -r '.signed_url')
FILENAME=$(echo "$RESPONSE" | jq -r '.filename')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Let's break down this signed URL:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract components
BASE_URL=$(echo "$SIGNED_URL" | cut -d'?' -f1)
PARAMS=$(echo "$SIGNED_URL" | cut -d'?' -f2)

echo "🌐 Base URL:"
echo "   $BASE_URL"
echo ""

echo "🔑 Authentication Parameters:"
echo "$PARAMS" | tr '&' '\n' | while read param; do
  KEY=$(echo "$param" | cut -d'=' -f1)
  VALUE=$(echo "$param" | cut -d'=' -f2)

  case $KEY in
    "X-Goog-Algorithm")
      echo "   ✓ Algorithm: $VALUE (RSA signature)"
      ;;
    "X-Goog-Expires")
      echo "   ✓ Expires in: $VALUE seconds ($(($VALUE / 60)) minutes)"
      ;;
    "X-Goog-Date")
      echo "   ✓ Created at: $VALUE"
      ;;
    "X-Goog-Signature")
      TRUNCATED="${VALUE:0:50}..."
      echo "   ✓ Signature: $TRUNCATED"
      ;;
  esac
done
echo ""

read -p "Press Enter to upload a file using this signed URL..."
echo ""

# Create test file
TEST_FILE="/tmp/demo-signed-url.txt"
echo "This file was uploaded using a signed URL!" > "$TEST_FILE"
echo "Timestamp: $(date)" >> "$TEST_FILE"
echo "Method: Standard Signed URL (PUT)" >> "$TEST_FILE"

echo "Step 2: Uploading file directly to Cloud Storage..."
echo "   File: $TEST_FILE"
echo "   Destination: $FILENAME"
echo ""

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$SIGNED_URL" \
  -H 'Content-Type: text/plain' \
  --data-binary @"$TEST_FILE")

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Upload successful! (HTTP $HTTP_CODE)"
  echo "   File is now in Cloud Storage!"
else
  echo "⚠️  Upload returned HTTP $HTTP_CODE"
fi

echo ""
read -p "Press Enter to continue to Resumable URL demo..."
echo ""

# ==========================================
# PART 2: RESUMABLE URL
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PART 2: Resumable Upload URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Step 1: Requesting a resumable upload URL from backend..."
echo ""

RESUMABLE_RESPONSE=$(curl -s -X POST "${API_URL}/api/generate-resumable-url" \
  -H 'Content-Type: application/json' \
  -d '{
    "filename": "large-demo-file.txt",
    "content_type": "text/plain"
  }')

echo "✅ Response from backend:"
echo "$RESUMABLE_RESPONSE" | jq .
echo ""

RESUMABLE_URL=$(echo "$RESUMABLE_RESPONSE" | jq -r '.resumable_url')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Resumable URL Breakdown:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Upload endpoint:"
echo "   $(echo "$RESUMABLE_URL" | cut -d'?' -f1)"
echo ""
echo "🆔 Session ID:"
echo "   $(echo "$RESUMABLE_URL" | grep -o 'upload_id=[^&]*' | cut -d'=' -f2 | head -c 50)..."
echo ""
echo "⏱️  Timeout: 1 hour"
echo "📦 Supports: Chunked uploads, pause/resume"
echo ""

# ==========================================
# PART 3: COMPARISON
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "COMPARISON: Signed URL vs Resumable URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "┌─────────────────────┬───────────────────┬──────────────────────┐"
echo "│ Feature             │ Signed URL        │ Resumable URL        │"
echo "├─────────────────────┼───────────────────┼──────────────────────┤"
echo "│ Timeout             │ 15 minutes        │ 1 hour               │"
echo "│ Upload method       │ Single PUT        │ Chunked PUT          │"
echo "│ Best for            │ Small files       │ Large files          │"
echo "│ Pause/Resume        │ No                │ Yes                  │"
echo "│ Network recovery    │ No                │ Yes                  │"
echo "│ Complexity          │ Simple            │ More complex         │"
echo "└─────────────────────┴───────────────────┴──────────────────────┘"
echo ""

# ==========================================
# PART 4: VIEW UPLOADED FILES
# ==========================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Your Uploaded Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FILES=$(curl -s "${API_URL}/api/list-files")
echo "$FILES" | jq -r '.files[] | "📄 \(.name)\n   Size: \(.size) bytes\n   Type: \(.content_type)\n"'

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║                    ✅ Demo Complete!                          ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎓 What you learned:"
echo "   • How signed URLs are structured"
echo "   • How to generate them via API"
echo "   • Difference between signed and resumable URLs"
echo "   • How to use them for direct uploads"
echo ""
echo "📚 Read more:"
echo "   • VIEW_SIGNED_URLS.md - Detailed guide"
echo "   • LEARNING.md - Concepts and theory"
echo ""
echo "🧪 Try it yourself:"
echo "   curl -X POST '${API_URL}/api/generate-signed-url' \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"filename\": \"test.txt\", \"content_type\": \"text/plain\"}' | jq ."
echo ""
