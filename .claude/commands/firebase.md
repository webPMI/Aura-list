# /firebase - Firebase Operations

Manage Firebase integration for the checklist app.

## Arguments
- `$ARGUMENTS` - Action: `deploy`, `rules`, `indexes`, `emulators`

## Instructions

### For `deploy`:
1. Build web version: `flutter build web`
2. Deploy to Firebase Hosting: `firebase deploy --only hosting`
3. Report the deployed URL

### For `rules`:
1. Show current Firestore security rules
2. Offer to update rules for tasks collection
3. Deploy rules: `firebase deploy --only firestore:rules`

### For `indexes`:
1. Show current Firestore indexes
2. Check for missing indexes in recent queries
3. Deploy indexes: `firebase deploy --only firestore:indexes`

### For `emulators`:
1. Start Firebase emulators: `firebase emulators:start`
2. Report emulator URLs (Auth, Firestore, etc.)

## Prerequisites:
- Firebase CLI installed (`npm install -g firebase-tools`)
- Project initialized (`firebase init`)
- Logged in (`firebase login`)
