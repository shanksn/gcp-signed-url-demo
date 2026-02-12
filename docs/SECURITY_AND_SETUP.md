# Security and Setup Guide

## 🔒 Sensitive Files - DO NOT COMMIT

This project contains several sensitive files that must **NEVER** be committed to GitHub:

### 1. Service Account Key Files
```
service-account-key.json
backend/service-account-key.json
```
**Why it's sensitive:** Contains the private key used to cryptographically sign URLs. Anyone with this key can:
- Generate signed URLs for your bucket
- Impersonate your service account
- Access GCP resources

**Why we need it:**
- Backend needs the private key to generate signed URLs using `blob.generate_signed_url()`
- Firebase Admin SDK uses it to verify tokens
- Required for both local development and App Engine deployment

**How it's protected:**
- Listed in `.gitignore`
- Created by Terraform automatically
- File permissions set to 0600 (owner read/write only)

### 2. Firebase Configuration
```
frontend/firebase-config.js
```
**Contains:** Your Firebase project credentials (API key, project ID, etc.)

**Note:** The Firebase `apiKey` is actually safe to expose publicly (it's not a secret), but it's better to keep your configuration private and provide a template instead.

### 3. Terraform Files
```
terraform.tfvars          # Your actual project ID
terraform.tfstate         # May contain sensitive output values
terraform.tfstate.backup  # Backup of state file
.terraform.lock.hcl       # Dependency lock file
```

**Why sensitive:** State files can contain sensitive information like service account keys and resource IDs.

## ✅ What IS Safe to Commit

- Source code (Python, JavaScript, HTML)
- Documentation (all .md files)
- Template/example files (.example.js, .example.tfvars)
- Infrastructure as Code (main.tf, variables.tf, outputs.tf)
- Requirements files (requirements.txt, package.json)
- Configuration files (app.yaml, .gitignore)

## 🛡️ GitHub Security Best Practices

### Before First Commit

1. **Review `.gitignore`:**
   ```bash
   cat .gitignore
   ```
   Ensure all sensitive files are listed.

2. **Check what will be committed:**
   ```bash
   git status
   git diff --cached
   ```

3. **Never force add ignored files:**
   ```bash
   # DON'T DO THIS:
   git add -f service-account-key.json  # ❌ NEVER!
   ```

### If You Accidentally Commit Sensitive Data

**IMPORTANT:** Simply deleting the file in a new commit doesn't remove it from git history!

1. **Remove from git history:**
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch service-account-key.json" \
     --prune-empty --tag-name-filter cat -- --all
   ```

2. **Force push (WARNING: rewrites history):**
   ```bash
   git push origin --force --all
   ```

3. **Rotate the compromised credentials:**
   - Delete the service account key in GCP Console
   - Create a new key with Terraform
   - Update Firebase config if exposed

4. **Better alternative - use BFG Repo-Cleaner:**
   ```bash
   brew install bfg  # or download from https://rtyley.github.io/bfg-repo-cleaner/
   bfg --delete-files service-account-key.json
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   git push --force
   ```

## 📋 Pre-Commit Checklist

Before every commit, verify:

- [ ] No `*.json` files containing keys (except .example files)
- [ ] No `terraform.tfstate` files
- [ ] No `terraform.tfvars` with real project IDs
- [ ] No API keys or secrets in code
- [ ] `.gitignore` is up to date
- [ ] Template/example files are provided for any required configs

## 🔍 Scanning for Secrets

Use tools to automatically detect secrets:

```bash
# Install gitleaks
brew install gitleaks

# Scan repository
gitleaks detect --source . --verbose

# Scan before commit (add to pre-commit hook)
gitleaks protect --staged --verbose
```

## 🌐 Production Deployment Notes

### Service Account Key on App Engine

When deploying to App Engine, the service account key file is deployed with your code. This is secure because:

1. **App Engine instances are isolated** - Only your application can access the file
2. **IAM controls access** - Only authorized users can deploy to App Engine
3. **Files are not publicly accessible** - Unlike static hosting
4. **Alternative approach:** Use Workload Identity (more complex but more secure)

### Better Alternative: Workload Identity

For production, consider using Workload Identity instead of service account keys:

```python
# No key file needed - uses App Engine's default service account
storage_client = storage.Client()
```

This requires:
- Granting Cloud Storage permissions to the App Engine service account
- Removing explicit key file loading from code
- More secure as there's no key file to leak

## 📚 Additional Resources

- [GCP Best Practices for Service Account Keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

## ❓ FAQ

**Q: Why not use environment variables for the service account key?**
A: The key is a JSON file with multiple fields. While you could encode it as a base64 string in an env var, it's more practical to use the file directly. App Engine supports deploying files securely.

**Q: Can I use Google Secret Manager instead?**
A: Yes! That's a better approach for production:
```python
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
response = client.access_secret_version(request={"name": "projects/PROJECT/secrets/KEY/versions/latest"})
key_data = response.payload.data.decode("UTF-8")
```

**Q: Is the Firebase API key a secret?**
A: No, Firebase API keys are safe to expose in client-side code. They're used to identify your Firebase project, not for authentication. Security is enforced through Firebase Security Rules and Authentication.

**Q: What if someone finds my service account key?**
A: Immediately revoke it in GCP Console:
1. Go to IAM & Admin → Service Accounts
2. Find `url-signer@PROJECT.iam.gserviceaccount.com`
3. Go to Keys tab
4. Delete the compromised key
5. Create a new one with Terraform: `terraform apply`
