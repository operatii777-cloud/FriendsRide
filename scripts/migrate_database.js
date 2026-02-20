const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Simple geohash calculation for migration purposes
function calculateSimpleGeohash(lat, lng) {
  // This is a simplified geohash for migration
  // In production, use a proper geohash library
  const latHash = Math.floor(lat * 1000);
  const lngHash = Math.floor(lng * 1000);
  return `${latHash}_${lngHash}`;
}

// Add geohash and isOnline fields to existing driver locations
async function migrateDriverLocations() {
  console.log('🚀 Starting migration of driver locations...');
  
  try {
    const driversSnapshot = await db.collection('driver_locations').get();
    
    if (driversSnapshot.empty) {
      console.log('ℹ️  No driver locations found to migrate.');
      return;
    }
    
    console.log(`📊 Found ${driversSnapshot.size} driver locations to migrate.`);
    
    const batch = db.batch();
    let updatedCount = 0;
    let skippedCount = 0;
    
    driversSnapshot.docs.forEach(doc => {
      const data = doc.data();
      
      // Check if migration is needed
      if (data.position && (!data.geohash || data.isOnline === undefined)) {
        const geohash = data.geohash || calculateSimpleGeohash(
          data.position.latitude, 
          data.position.longitude
        );
        
        const updateData = {
          geohash: geohash,
          isOnline: data.isOnline !== undefined ? data.isOnline : false,
          lastUpdate: data.lastUpdate || admin.firestore.FieldValue.serverTimestamp()
        };
        
        batch.update(doc.ref, updateData);
        updatedCount++;
        
        console.log(`✅ Updated driver ${doc.id} with geohash: ${geohash}`);
      } else {
        skippedCount++;
        console.log(`⏭️  Skipped driver ${doc.id} (already migrated or missing position)`);
      }
    });
    
    if (updatedCount > 0) {
      await batch.commit();
      console.log(`🎉 Successfully migrated ${updatedCount} driver locations!`);
    } else {
      console.log('ℹ️  No updates needed - all drivers are already migrated.');
    }
    
    console.log(`📈 Migration Summary:`);
    console.log(`   - Updated: ${updatedCount}`);
    console.log(`   - Skipped: ${skippedCount}`);
    console.log(`   - Total: ${driversSnapshot.size}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Create indexes for better performance
async function createIndexes() {
  console.log('🔧 Creating Firestore indexes for better performance...');
  
  try {
    // Note: Indexes are created automatically by Firestore when needed
    // This is just for documentation purposes
    
    console.log('📋 Recommended indexes to create in Firebase Console:');
    console.log('   Collection: driver_locations');
    console.log('   Fields:');
    console.log('     - category (Ascending)');
    console.log('     - geohash (Ascending)');
    console.log('     - isOnline (Ascending)');
    console.log('     - lastUpdate (Descending)');
    
    console.log('✅ Index creation instructions provided.');
    
  } catch (error) {
    console.error('❌ Index creation failed:', error);
    throw error;
  }
}

// Main migration function
async function runMigration() {
  console.log('🏗️  FriendsRide Database Migration - Phase 1');
  console.log('==========================================');
  
  try {
    await migrateDriverLocations();
    await createIndexes();
    
    console.log('🎯 Migration completed successfully!');
    console.log('📝 Next steps:');
    console.log('   1. Deploy Firestore security rules');
    console.log('   2. Test the application thoroughly');
    console.log('   3. Monitor Firestore costs and performance');
    
  } catch (error) {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  runMigration();
}

module.exports = {
  runMigration,
  migrateDriverLocations,
  createIndexes
};
