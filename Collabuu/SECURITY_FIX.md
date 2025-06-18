# 🚨 SECURITY FIX REQUIRED

## Issue
Your repository contains hardcoded Supabase JWT tokens that have been detected by GitHub's secret scanning. These need to be removed immediately.

## Fixed Files
✅ The following files have been updated to remove hardcoded secrets:
- `scripts/setup-database.js`
- `scripts/create-missing-tables.js` 
- `Supabase/Config/SupabaseConfig.swift`
- `tests/api-test-framework.js`

## Required Actions

### 1. Create Environment Variables
Create a `.env` file in the `Collabuu/` directory with:

```bash
# Supabase Configuration  
SUPABASE_URL=https://eecixpooqqhifvmpcdnp.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_KEY=your-service-role-key-here

# API Configuration
API_BASE_URL=http://localhost:3001
PORT=3001

# Development/Testing
NODE_ENV=development
```

### 2. Regenerate Your Supabase Keys
⚠️ **CRITICAL**: Since your keys were exposed publicly, you should:

1. Go to your Supabase dashboard: https://supabase.com/dashboard/project/eecixpooqqhifvmpcdnp
2. Go to Settings → API
3. **Reset your Service Role Key** (the exposed one)
4. Update your `.env` file with the new keys

### 3. Update Swift iOS App
For the iOS app, add your keys to `Info.plist`:

```xml
<key>SUPABASE_URL</key>
<string>https://eecixpooqqhifvmpcdnp.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your-anon-key-here</string>
<key>SUPABASE_SERVICE_KEY</key>
<string>your-service-role-key-here</string>
```

### 4. Add .env to .gitignore
Ensure your `.gitignore` includes:
```
.env
.env.local
.env.*.local
```

### 5. Commit and Push Changes
After setting up environment variables:
```bash
git add .
git commit -m "fix: remove hardcoded secrets, use environment variables"
git push
```

## Security Best Practices
- ✅ Never commit API keys or secrets to version control
- ✅ Use environment variables for all sensitive configuration
- ✅ Use different keys for development/staging/production
- ✅ Regularly rotate API keys
- ✅ Set up proper Row Level Security (RLS) in Supabase 