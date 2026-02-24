const admin = require('firebase-admin');
const fs = require('fs');

async function debugAuth() {
    if (!fs.existsSync('./firebase-service-account.json')) {
        console.error('❌ Error: firebase-service-account.json not found');
        process.exit(1);
    }

    const serviceAccount = require('../firebase-service-account.json');

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });

    const email = 'servicioweb.pmi@gmail.com';

    console.log(`🔍 Checking user: ${email}...`);

    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        console.log('✅ User found in Auth:');
        console.log(`   UID: ${userRecord.uid}`);
        console.log(`   Email Verified: ${userRecord.emailVerified}`);
        console.log(`   Disabled: ${userRecord.disabled}`);

        // Check if user is in Firestore admins collection
        const db = admin.firestore();
        const adminDoc = await db.collection('admins').doc(userRecord.uid).get();

        if (adminDoc.exists) {
            console.log('✅ User found in Firestore "admins" collection:');
            console.log('   Data:', adminDoc.data());
        } else {
            console.log('❌ User NOT found in Firestore "admins" collection');
        }
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            console.log('❌ User NOT found in Firebase Auth');
        } else {
            console.error('❌ Error checking user:', error.message);
        }
    }

    process.exit(0);
}

debugAuth();
