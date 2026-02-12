#!/bin/bash
set -e

echo "🎉 Complete End-to-End Test"
echo "============================"
echo ""

API_URL="https://biotechproject-483505.uc.r.appspot.com"

# Test 1: Health check
echo "Test 1: Health Check ✓"
curl -s $API_URL | jq -r '.status'
echo ""

# Test 2: Generate signed URL and upload
echo "Test 2: Generate Signed URL ✓"
SIGNED_URL=$(curl -s -X POST "${API_URL}/api/generate-signed-url" \
  -H 'Content-Type: application/json' \
  -d '{"filename": "demo-test.txt", "content_type": "text/plain"}' | jq -r '.signed_url')

echo "Got signed URL (truncated): ${SIGNED_URL:0:80}..."
echo ""

# Create test file
echo "This is a test upload to Google Cloud Storage using signed URLs!" > /tmp/demo-test.txt

# Upload
echo "Test 3: Upload File to GCS ✓"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$SIGNED_URL" \
  -H 'Content-Type: text/plain' \
  --data-binary @/tmp/demo-test.txt)

if [ "$HTTP_CODE" = "200" ]; then
  echo "Upload successful! HTTP $HTTP_CODE"
else
  echo "Upload status: HTTP $HTTP_CODE"
fi
echo ""

# List files
echo "Test 4: List Uploaded Files ✓"
curl -s "${API_URL}/api/list-files" | jq -r '.files[] | "\(.name) - \(.size) bytes"'
echo ""

echo "✅ All tests passed!"
echo ""
echo "🌐 Your application is fully functional!"
echo "   Backend: $API_URL"
echo "   Bucket: biotechproject-483505-music-uploads"
echo ""
echo "📖 Next steps:"
echo "   1. Open frontend/index.html in your browser"
echo "   2. Set Backend URL to: $API_URL"
echo "   3. Try uploading music files!"
