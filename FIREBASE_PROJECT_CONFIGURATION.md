# Firebase Project Configuration Steps

## 6. Configure Flutter App for New Firebase Project

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Configure Firebase for Flutter
```bash
# In your project root
firebase projects:list
firebase use your-new-project-id

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

### Step 3: Update firebase_options.dart
The `flutterfire configure` command will update your `lib/firebase_options.dart` file with the new project configuration.

### Step 4: Update .firebaserc
```json
{
  "projects": {
    "default": "your-new-project-id"
  }
}
```

## 7. Deploy Firestore Rules and Indexes

### Deploy Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Indexes  
```bash
firebase deploy --only firestore:indexes
```

## 8. Test the New Setup

### Verification Checklist
- [ ] Authentication works (sign up/sign in)
- [ ] User profile creation works
- [ ] Data writes to correct collections
- [ ] Security rules prevent unauthorized access
- [ ] Indexes support your queries

### Test Commands
```bash
# Test Firestore rules
firebase emulators:start --only firestore
# Run your app against local emulator first
```
## 9. Data Migration (Optional)

If you want to migrate existing data from your old project:

### Export Data from Old Project
```bash
# Install firestore-export-import
npm install -g firestore-export-import

# Export data
firestore-export --accountCredentials path/to/old-project-key.json --backupFile backup.json
```

### Import Data to New Project  
```bash
# Import data
firestore-import --accountCredentials path/to/new-project-key.json --backupFile backup.json
```

## 10. Environment Configuration

### Development vs Production
Consider setting up multiple Firebase projects:
- `mindnest-dev` (development)
- `mindnest-prod` (production)

### Update .firebaserc for multiple environments
```json
{
  "projects": {
    "dev": "mindnest-dev",
    "prod": "mindnest-prod", 
    "default": "mindnest-dev"
  }
}
```

### Switch between environments
```bash
firebase use dev    # Switch to development
firebase use prod   # Switch to production
```

## 11. Quota Management Best Practices

### Implement Caching
- Use local caching for frequently accessed data
- Implement offline persistence
- Batch read/write operations

### Monitor Usage
- Set up billing alerts in Firebase Console
- Monitor quota usage in Usage tab
- Implement quota monitoring in your app

### Optimize Queries
- Use proper indexing
- Limit query results with `.limit()`
- Use pagination for large datasets
- Avoid real-time listeners for static data