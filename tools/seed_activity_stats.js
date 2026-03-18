// seed_activity_stats.js
// Requires Firebase Admin SDK.
// Run: node tools/seed_activity_stats.js

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const UID = 'tlpk3ittDbPtZ1yN9T0U231U46D3'; // Pradnyil Patil (godpradnyil31@gmail.com)

async function seed() {
  // Only update the meditation document — journaling, smart_goals,
  // daily_checkin etc. are already created by the app automatically.
  const meditationRef = db
    .collection('users')
    .doc(UID)
    .collection('activity_stats')
    .doc('meditation');

  await meditationRef.set(
    {
      completionCount: 14,
      lastCompleted: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  console.log('✅ Done! meditation completionCount = 14');
  console.log('   Complete 1 more meditation in the app to trigger the Meditation Master badge!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});
