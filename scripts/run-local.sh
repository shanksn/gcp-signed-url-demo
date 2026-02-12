#!/bin/bash

# Local development script
# Runs the backend and opens the frontend in browser

set -e

echo "🧪 Running GCS Signed URL Demo locally"
echo "======================================="

# Check if Terraform has been applied
if [ ! -f service-account-key.json ]; then
    echo "❌ service-account-key.json not found!"
    echo "Please run 'terraform apply' first to create infrastructure"
    exit 1
fi

# Get bucket name from Terraform
BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null)
SA_EMAIL=$(terraform output -raw service_account_email 2>/dev/null)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Unable to get bucket name from Terraform"
    echo "Please run 'terraform apply' first"
    exit 1
fi

echo "✅ Configuration:"
echo "   Bucket: $BUCKET_NAME"
echo "   Service Account: $SA_EMAIL"
echo ""

# Set environment variables
export BUCKET_NAME="$BUCKET_NAME"
export SERVICE_ACCOUNT_EMAIL="$SA_EMAIL"
export GOOGLE_APPLICATION_CREDENTIALS="./service-account-key.json"

# Check if Python virtual environment exists
if [ ! -d "backend/venv" ]; then
    echo "📦 Creating Python virtual environment..."
    cd backend
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    cd ..
else
    cd backend
    source venv/bin/activate
    cd ..
fi

# Kill any existing processes on ports 8080 and 8000
echo "🧹 Cleaning up existing processes..."
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:8000 | xargs kill -9 2>/dev/null || true

# Start backend
echo ""
echo "🚀 Starting backend on http://localhost:8080..."
cd backend
python main.py &
BACKEND_PID=$!
cd ..

# Wait for backend to start
sleep 2

# Start frontend
echo "🚀 Starting frontend on http://localhost:8000..."
cd frontend
python3 -m http.server 8000 &
FRONTEND_PID=$!
cd ..

# Wait for frontend to start
sleep 2

echo ""
echo "✅ Services running:"
echo "   Backend API: http://localhost:8080"
echo "   Frontend:    http://localhost:8000"
echo ""
echo "🌐 Opening browser..."
open http://localhost:8000 2>/dev/null || echo "Please open http://localhost:8000 in your browser"

echo ""
echo "📝 Backend logs will appear below (Ctrl+C to stop all services):"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    echo "✅ Services stopped"
    exit 0
}

trap cleanup INT TERM

# Wait for processes
wait
