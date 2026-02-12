"""
App Engine backend for generating signed URLs for Cloud Storage uploads.
Demonstrates three types of signed URLs:
1. Standard signed URL (PUT method) - for direct uploads
2. Signed POST URL - for browser form uploads
3. Resumable upload URL - for large files with pause/resume capability
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from google.cloud import storage
from datetime import datetime, timedelta
import json
import os
from auth import require_auth  # Import Firebase authentication

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
BUCKET_NAME = os.environ.get('BUCKET_NAME', '')
SERVICE_ACCOUNT_EMAIL = os.environ.get('SERVICE_ACCOUNT_EMAIL', '')

# Initialize storage client with service account credentials
# For App Engine, we need to explicitly use the service account key
KEY_PATH = os.path.join(os.path.dirname(__file__), 'service-account-key.json')
if os.path.exists(KEY_PATH):
    storage_client = storage.Client.from_service_account_json(KEY_PATH)
else:
    # Fallback to default credentials for local development
    storage_client = storage.Client()


@app.route('/')
def index():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Signed URL Generator',
        'bucket': BUCKET_NAME,
        'endpoints': {
            'standard_signed_url': '/api/generate-signed-url',
            'post_signed_url': '/api/generate-post-url',
            'resumable_url': '/api/generate-resumable-url'
        }
    })


@app.route('/api/generate-signed-url', methods=['POST'])
@require_auth  # 🔒 NOW REQUIRES FIREBASE AUTHENTICATION!
def generate_signed_url(user):  # 'user' parameter added by @require_auth decorator
    """
    Generate a standard signed URL for PUT method upload.
    NOW REQUIRES AUTHENTICATION - only logged-in users can request signed URLs!

    Request headers:
    {
        "Authorization": "Bearer <firebase-id-token>",
        "Content-Type": "application/json"
    }

    Request body:
    {
        "filename": "song.mp3",
        "content_type": "audio/mpeg"
    }
    """
    try:
        # Extract user info from Firebase token
        user_id = user['uid']  # Unique user ID from Firebase
        user_email = user.get('email', 'unknown')  # User's email

        data = request.get_json()
        filename = data.get('filename')
        content_type = data.get('content_type', 'application/octet-stream')

        if not filename:
            return jsonify({'error': 'filename is required'}), 400

        # Generate unique filename with USER ID and timestamp
        # Files are now organized by user!
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"uploads/{user_id}/{timestamp}_{filename}"

        # Log who's uploading (for debugging)
        print(f"✅ User {user_email} ({user_id}) requesting signed URL for {filename}")

        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(unique_filename)

        # Generate signed URL valid for 15 minutes
        url = blob.generate_signed_url(
            version="v4",
            expiration=timedelta(minutes=15),
            method="PUT",
            content_type=content_type
        )

        return jsonify({
            'signed_url': url,
            'filename': unique_filename,
            'method': 'PUT',
            'content_type': content_type,
            'expires_in': '15 minutes',
            'user_email': user_email,  # NEW: Include who requested this
            'instructions': 'Use PUT method to upload file directly to this URL'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/generate-post-url', methods=['POST'])
@require_auth  # 🔒 NOW REQUIRES FIREBASE AUTHENTICATION!
def generate_post_url(user):  # 'user' parameter added by @require_auth decorator
    """
    Generate a signed POST policy for form-based uploads.
    This allows HTML forms to upload directly to Cloud Storage.
    NOW REQUIRES AUTHENTICATION!

    Request headers:
    {
        "Authorization": "Bearer <firebase-id-token>",
        "Content-Type": "application/json"
    }

    Request body:
    {
        "filename": "song.mp3",
        "content_type": "audio/mpeg"
    }
    """
    try:
        # Extract user info from Firebase token
        user_id = user['uid']
        user_email = user.get('email', 'unknown')

        data = request.get_json()
        filename = data.get('filename')
        content_type = data.get('content_type', 'application/octet-stream')

        if not filename:
            return jsonify({'error': 'filename is required'}), 400

        # Generate unique filename with USER ID and timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"uploads/{user_id}/{timestamp}_{filename}"

        print(f"✅ User {user_email} ({user_id}) requesting POST URL for {filename}")

        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(unique_filename)

        # Generate POST policy
        policy = blob.generate_signed_post_policy_v4(
            expiration=timedelta(minutes=15),
            conditions=[
                ["content-length-range", 0, 104857600],  # Max 100MB
                ["starts-with", "$Content-Type", ""]
            ]
        )

        return jsonify({
            'url': policy['url'],
            'fields': policy['fields'],
            'filename': unique_filename,
            'method': 'POST',
            'expires_in': '15 minutes',
            'max_file_size': '100MB',
            'user_email': user_email,  # NEW: Include who requested this
            'instructions': 'Use POST method with form-data including all fields'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/generate-resumable-url', methods=['POST'])
@require_auth  # 🔒 NOW REQUIRES FIREBASE AUTHENTICATION!
def generate_resumable_url(user):  # 'user' parameter added by @require_auth decorator
    """
    Generate a resumable upload URL for large files.
    Allows pausing and resuming uploads.
    NOW REQUIRES AUTHENTICATION!

    Request body:
    {
        "filename": "large-album.zip",
        "content_type": "application/zip"
    }
    """
    try:
        # Extract user info from Firebase token
        user_id = user['uid']
        user_email = user.get('email', 'unknown')

        data = request.get_json()
        filename = data.get('filename')
        content_type = data.get('content_type', 'application/octet-stream')

        if not filename:
            return jsonify({'error': 'filename is required'}), 400

        # Generate unique filename with USER ID and timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"uploads/{user_id}/{timestamp}_{filename}"

        print(f"✅ User {user_email} ({user_id}) requesting resumable URL for {filename}")

        bucket = storage_client.bucket(BUCKET_NAME)
        blob = bucket.blob(unique_filename)

        # Generate resumable upload URL
        url = blob.create_resumable_upload_session(
            content_type=content_type,
            timeout=3600  # 1 hour timeout
        )

        return jsonify({
            'resumable_url': url,
            'filename': unique_filename,
            'method': 'PUT',
            'content_type': content_type,
            'timeout': '1 hour',
            'instructions': 'Use PUT method to upload chunks. Supports pause/resume.'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/list-files', methods=['GET'])
@require_auth  # 🔒 NOW REQUIRES FIREBASE AUTHENTICATION!
def list_files(user):  # 'user' parameter added by @require_auth decorator
    """
    List uploaded files for the authenticated user.
    NOW REQUIRES AUTHENTICATION - users can only see their own files!
    """
    try:
        user_id = user['uid']
        user_email = user.get('email', 'unknown')

        print(f"✅ User {user_email} ({user_id}) listing their files")

        bucket = storage_client.bucket(BUCKET_NAME)
        # Only list files for this specific user
        blobs = list(bucket.list_blobs(prefix=f'uploads/{user_id}/', max_results=50))

        files = []
        for blob in blobs:
            files.append({
                'name': blob.name,
                'size': blob.size,
                'content_type': blob.content_type,
                'created': blob.time_created.isoformat() if blob.time_created else None,
                'public_url': f"https://storage.googleapis.com/{BUCKET_NAME}/{blob.name}"
            })

        return jsonify({
            'files': files,
            'count': len(files)
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # For local development only
    app.run(host='127.0.0.1', port=8081, debug=True)
