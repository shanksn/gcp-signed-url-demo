"""
Firebase Authentication middleware for Flask

This module provides Firebase authentication for your Flask backend.
It verifies Firebase ID tokens sent from the frontend.
"""

import firebase_admin
from firebase_admin import credentials, auth
from flask import request, jsonify
import functools
import os


# ============================================
# ACCESS CONTROL CONFIGURATION
# ============================================

# Email Whitelist - Only these email addresses can access the API
# Add or remove emails as needed
ALLOWED_EMAILS = [
    'shanksreader@gmail.com',  # Add your allowed email addresses here
    # 'another-user@gmail.com',
    # 'user@company.com',
]


def is_user_allowed(email):
    """
    Check if a user's email is allowed based on whitelist.

    Args:
        email (str): User's email address

    Returns:
        tuple: (bool, str) - (is_allowed, reason_if_denied)
    """
    if not email:
        return False, "No email found in token"

    # Check if email is in whitelist (case-insensitive)
    email_lower = email.lower()
    allowed_emails_lower = [e.lower() for e in ALLOWED_EMAILS]

    if email_lower in allowed_emails_lower:
        return True, None
    else:
        return False, f"Email '{email}' is not authorized to access this application"


# Initialize Firebase Admin SDK
# Uses the same service account key created by Terraform
KEY_PATH = os.path.join(os.path.dirname(__file__), 'service-account-key.json')

try:
    cred = credentials.Certificate(KEY_PATH)
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin SDK initialized successfully")
except Exception as e:
    print(f"⚠️  Firebase initialization error: {e}")
    print(f"   Make sure {KEY_PATH} exists")


def require_auth(f):
    """
    Decorator to require Firebase authentication for a Flask route.

    Usage:
        @app.route('/api/protected')
        @require_auth
        def protected_route(user):
            user_id = user['uid']
            user_email = user.get('email')
            # ... your code ...

    The decorated function receives the decoded Firebase token as 'user' parameter.

    Token structure:
        {
            'uid': 'abc123...',  # Unique user ID
            'email': 'user@gmail.com',
            'name': 'John Doe',
            'picture': 'https://...',
            # ... other claims ...
        }
    """
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        # Get the ID token from Authorization header
        auth_header = request.headers.get('Authorization', '')

        if not auth_header.startswith('Bearer '):
            return jsonify({
                'error': 'Missing or invalid Authorization header',
                'hint': 'Include: Authorization: Bearer YOUR_FIREBASE_TOKEN'
            }), 401

        id_token = auth_header.replace('Bearer ', '')

        try:
            # Verify the ID token with Firebase
            # This checks:
            # - Token signature is valid
            # - Token hasn't expired
            # - Token was issued by Firebase
            decoded_token = auth.verify_id_token(id_token)

            # Check if user is in whitelist
            user_email = decoded_token.get('email', 'unknown')
            is_allowed, deny_reason = is_user_allowed(user_email)

            if not is_allowed:
                print(f"🚫 Access denied for user: {user_email} - {deny_reason}")
                return jsonify({
                    'error': 'Access Denied',
                    'message': deny_reason,
                    'hint': 'Contact the administrator to request access'
                }), 403

            # Log successful auth
            print(f"✅ Authenticated user: {user_email}")

            # Pass the decoded token to the route function
            return f(decoded_token, *args, **kwargs)

        except auth.ExpiredIdTokenError:
            return jsonify({
                'error': 'Token has expired',
                'hint': 'Please sign in again to get a new token'
            }), 401

        except auth.RevokedIdTokenError:
            return jsonify({
                'error': 'Token has been revoked',
                'hint': 'Please sign in again'
            }), 401

        except auth.InvalidIdTokenError:
            return jsonify({
                'error': 'Invalid token',
                'hint': 'Token format is incorrect or tampered with'
            }), 401

        except Exception as e:
            return jsonify({
                'error': f'Authentication failed: {str(e)}'
            }), 401

    return decorated_function


# Optional: Function to get user info without decorator
def get_current_user():
    """
    Get the current authenticated user from the request.

    Returns:
        dict: Decoded Firebase token, or None if not authenticated

    Usage:
        user = get_current_user()
        if user:
            print(f"User {user['email']} is logged in")
    """
    auth_header = request.headers.get('Authorization', '')

    if not auth_header.startswith('Bearer '):
        return None

    id_token = auth_header.replace('Bearer ', '')

    try:
        return auth.verify_id_token(id_token)
    except:
        return None
