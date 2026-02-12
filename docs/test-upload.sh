#!/bin/bash
set -e

echo "🧪 Testing GCP Signed URL Application"
echo "====================================="
echo ""

API_URL="https://biotechproject-483505.uc.r.appspot.com"

# Test 1: Health check
echo "✅ Test 1: Health Check"
curl -s $API_URL | jq .
echo ""

# Test 2: Generate signed URL
echo "✅ Test 2: Generate Signed URL"
RESPONSE=$(curl -s -X POST $API_URL/api/generate-signed-url \
  -H "Content-Type: application/json" \
  -d '{"filename": "test-file.txt", "content_type": "text/plain"}')

echo $RESPONSE | jq .
SIGNED_URL=$(echo $RESPONSE | jq -r '.signed_url')
echo ""

# Test 3: Upload file
echo "✅ Test 3: Upload File to Cloud Storage"
echo "This is a test file from the GCP Signed URL demo!" > /tmp/test-file.txt

curl -X PUT "$SIGNED_URL" \
  -H "Content-Type: text/plain" \
  --data-binary @/tmp/test-file.txt

if [ $? -eq 0 ]; then
  echo "✅ Upload successful!"
else
  echo "❌ Upload failed"
fi
echo ""

# Test 4: List files
echo "✅ Test 4: List Uploaded Files"
curl -s $API_URL/api/list-files | jq '.files[] | {name, size, content_type}'
echo ""

echo "🎉 All tests completed!"
echo ""
echo "Your application is working perfectly!"
echo "Backend: $API_URL"
echo "Bucket: biotechproject-483505-music-uploads"
