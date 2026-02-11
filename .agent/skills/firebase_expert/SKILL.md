---
name: Firebase Expert
description: Expert guidance for Firebase integration and operations in AuraList.
---

# Firebase Expert Skill

This skill provides expert guidance for Firebase operations within the AuraList project.

## Core Principles
- **Offline-First**: Ensure the app works without internet using local storage (Hive) as the source of truth.
- **Robust Sync**: Implement reliable synchronization between local data and Firestore.
- **Secure by Default**: Follow best practices for Firestore security rules and authentication.

## Authentication Patterns
- **Anonymous-First**: Always start with an anonymous session to allow immediate app usage.
- **Account Linking**: Provide clear paths to link anonymous accounts with Email or Google.
- **Error Transparency**: Show specific Firebase error messages translated to Spanish for the user.

## Firestore Best Practices
- **Rules**: Always verify rules in `firestore.rules` for each collection.
- **Data Structure**: Use the established model-to-JSON mapping.
- **Queries**: Ensure all common queries have appropriate indexes.

## Sync Logic
- **Upload**: Local changes should be queued for upload when online.
- **Download**: Remote changes should be merged into the local database.
- **Conflicts**: Use last-write-wins or specific conflict resolution logic as defined in `SyncException`.

## Useful Commands
- `firebase deploy --only hosting`: Deploy web version.
- `firebase deploy --only firestore:rules`: Deploy security rules.
- `firebase emulators:start`: Start local emulators for testing.
