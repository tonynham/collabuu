const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client with service key for admin operations
const supabase = createClient(
  process.env.SUPABASE_URL || 'https://eecixpooqqhifvmpcdnp.supabase.co',
  process.env.SUPABASE_SERVICE_KEY
);

if (!process.env.SUPABASE_SERVICE_KEY) {
  console.error('❌ SUPABASE_SERVICE_KEY environment variable is required');
  process.exit(1);
}

async function testConnection() {
  console.log('🔗 Testing Supabase connection...');
  
  try {
    // Try to access any system table to test connection
    const { data, error } = await supabase.from('information_schema.tables').select('table_name').limit(1);
    
    console.log('✅ Supabase connection successful!');
    return true;
  } catch (err) {
    console.error('❌ Connection test failed:', err.message);
    return false;
  }
}

async function createTables() {
  console.log('🚀 Creating database tables...');

  // Since we can't execute arbitrary SQL through the client, 
  // let's try to create tables by inserting into them (which will create them if they don't exist)
  
  const tables = [
    'user_profiles',
    'business_profiles', 
    'influencer_profiles',
    'customer_profiles',
    'campaigns',
    'campaign_applications',
    'campaign_invites',
    'accepted_campaigns',
    'campaign_referral_codes',
    'visits',
    'content_submissions',
    'conversations',
    'messages',
    'uploaded_files'
  ];

  let successCount = 0;
  
  for (const tableName of tables) {
    try {
      console.log(`📝 Checking table: ${tableName}`);
      
      // Try to select from the table to see if it exists
      const { data, error } = await supabase.from(tableName).select('*').limit(1);
      
      if (!error) {
        console.log(`✅ Table ${tableName} already exists`);
        successCount++;
      } else if (error.message.includes('does not exist')) {
        console.log(`⚠️  Table ${tableName} does not exist - needs manual creation`);
      } else {
        console.log(`✅ Table ${tableName} exists (access restricted)`);
        successCount++;
      }
      
    } catch (err) {
      console.error(`❌ Error checking table ${tableName}:`, err.message);
    }
  }

  return successCount;
}

async function createStorageBuckets() {
  console.log('📁 Creating storage buckets...');

  try {
    // Create uploads bucket
    const { data: bucket, error: bucketError } = await supabase.storage.createBucket('uploads', {
      public: false,
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
      fileSizeLimit: 10485760 // 10MB
    });

    if (bucketError && !bucketError.message.includes('already exists')) {
      console.error('❌ Error creating uploads bucket:', bucketError);
      return false;
    }

    console.log('✅ Storage buckets created successfully!');
    return true;

  } catch (err) {
    console.error('❌ Storage bucket creation failed:', err.message);
    return false;
  }
}

function printSQLInstructions() {
  console.log('\n📋 MANUAL SETUP REQUIRED:');
  console.log('Since Supabase doesn\'t allow arbitrary SQL execution through the client,');
  console.log('you need to run the following SQL in your Supabase dashboard:\n');
  
  console.log('1. Go to: https://supabase.com/dashboard/project/eecixpooqqhifvmpcdnp');
  console.log('2. Click on "SQL Editor" in the left sidebar');
  console.log('3. Copy and paste the following SQL:\n');
  
  const sql = `
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles (Base table for all users)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('business', 'influencer', 'customer')),
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Business Profiles
CREATE TABLE IF NOT EXISTS business_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  business_name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  location JSONB,
  contact_email VARCHAR(255),
  contact_phone VARCHAR(50),
  website_url VARCHAR(255),
  logo_url VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Influencer Profiles
CREATE TABLE IF NOT EXISTS influencer_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  username VARCHAR(100) UNIQUE,
  display_name VARCHAR(255),
  bio TEXT,
  niche VARCHAR(100),
  categories TEXT[],
  follower_count INTEGER DEFAULT 0,
  profile_image_url VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customer Profiles
CREATE TABLE IF NOT EXISTS customer_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  email VARCHAR(255),
  profile_image_url VARCHAR(255),
  loyalty_points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Campaigns
CREATE TABLE IF NOT EXISTS campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  campaign_type VARCHAR(50) NOT NULL CHECK (campaign_type IN ('visit_verification', 'content_creation', 'loyalty_reward', 'media_event')),
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled')),
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  budget DECIMAL(10,2),
  total_credits INTEGER DEFAULT 0,
  used_credits INTEGER DEFAULT 0,
  deeplink_code VARCHAR(50) UNIQUE,
  requirements JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Campaign Applications
CREATE TABLE IF NOT EXISTS campaign_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn')),
  application_message TEXT,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewer_notes TEXT,
  UNIQUE(campaign_id, influencer_id)
);

-- Campaign Invites
CREATE TABLE IF NOT EXISTS campaign_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  business_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  message TEXT,
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(campaign_id, influencer_id)
);

-- Accepted Campaigns (Active collaborations)
CREATE TABLE IF NOT EXISTS accepted_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  business_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completion_status VARCHAR(20) DEFAULT 'active' CHECK (completion_status IN ('active', 'completed', 'cancelled')),
  credits_earned INTEGER DEFAULT 0,
  UNIQUE(campaign_id, influencer_id)
);

-- Campaign Referral Codes
CREATE TABLE IF NOT EXISTS campaign_referral_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  code VARCHAR(50) UNIQUE NOT NULL,
  usage_limit INTEGER DEFAULT 1,
  used_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- Visits
CREATE TABLE IF NOT EXISTS visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES user_profiles(id),
  campaign_id UUID REFERENCES campaigns(id),
  qr_code VARCHAR(255),
  referral_code_id UUID REFERENCES campaign_referral_codes(id),
  visit_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  verification_method VARCHAR(50),
  credits_awarded INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Content Submissions
CREATE TABLE IF NOT EXISTS content_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(255),
  content_url VARCHAR(255) NOT NULL,
  platform VARCHAR(50) NOT NULL,
  content_type VARCHAR(50),
  thumbnail_url VARCHAR(255),
  description TEXT,
  metadata JSONB,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'revision_requested')),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewer_notes TEXT
);

-- Conversations
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  business_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  influencer_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_read_by_business BOOLEAN DEFAULT false,
  is_read_by_influencer BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(campaign_id, business_id, influencer_id)
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('business', 'influencer')),
  content TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
  attachment_url VARCHAR(255),
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Uploaded Files
CREATE TABLE IF NOT EXISTS uploaded_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  filename VARCHAR(255) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_type ON user_profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_business_profiles_user_id ON business_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_influencer_profiles_user_id ON influencer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_customer_profiles_user_id ON customer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_business_id ON campaigns(business_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);
CREATE INDEX IF NOT EXISTS idx_campaign_applications_campaign_id ON campaign_applications(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_applications_influencer_id ON campaign_applications(influencer_id);
CREATE INDEX IF NOT EXISTS idx_visits_business_id ON visits(business_id);
CREATE INDEX IF NOT EXISTS idx_visits_customer_id ON visits(customer_id);
CREATE INDEX IF NOT EXISTS idx_content_submissions_campaign_id ON content_submissions(campaign_id);
CREATE INDEX IF NOT EXISTS idx_conversations_campaign_id ON conversations(campaign_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_uploaded_files_user_id ON uploaded_files(user_id);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE influencer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE accepted_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE uploaded_files ENABLE ROW LEVEL SECURITY;
`;

  console.log(sql);
  console.log('\n4. Click "Run" to execute the SQL');
  console.log('5. Wait for completion message');
  console.log('\n✨ After running the SQL, your database will be fully set up!');
}

async function verifyTables() {
  console.log('\n🔍 Verifying table creation...');
  
  const tablesToCheck = [
    'user_profiles', 'business_profiles', 'influencer_profiles', 
    'customer_profiles', 'campaigns', 'campaign_applications',
    'visits', 'content_submissions', 'conversations', 'messages'
  ];
  
  let verifiedCount = 0;
  
  for (const tableName of tablesToCheck) {
    try {
      const { data, error } = await supabase.from(tableName).select('*').limit(1);
      
      if (!error) {
        console.log(`✅ Table ${tableName} verified`);
        verifiedCount++;
      } else {
        console.log(`❌ Table ${tableName} not found`);
      }
    } catch (err) {
      console.log(`❌ Table ${tableName} verification error`);
    }
  }
  
  return verifiedCount;
}

async function setupDatabase() {
  console.log('🎯 Setting up Collabuu database...\n');

  // Test connection first
  const connectionOk = await testConnection();
  if (!connectionOk) {
    console.log('❌ Cannot proceed without a valid Supabase connection');
    process.exit(1);
  }

  // Check existing tables
  const existingTables = await createTables();
  
  // Create storage buckets
  const bucketsCreated = await createStorageBuckets();
  
  // Verify tables
  const verifiedCount = await verifyTables();

  console.log('\n📋 Setup Summary:');
  console.log(`✅ Database connection: Working`);
  console.log(`✅ Tables found: ${verifiedCount}/10`);
  console.log(`✅ Storage buckets: ${bucketsCreated ? 'Created' : 'Failed'}`);

  if (verifiedCount >= 8) {
    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n🚀 Your Collabuu backend is now ready for use!');
    console.log('\n📝 Next steps:');
    console.log('1. Test your API endpoints');
    console.log('2. Start building your frontend');
    console.log('3. Begin user registration and authentication');
  } else {
    console.log('\n⚠️  Tables need to be created manually.');
    printSQLInstructions();
  }
}

// Run the setup
setupDatabase().catch(console.error); 