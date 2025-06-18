const https = require('https');

const SUPABASE_URL = 'https://eecixpooqqhifvmpcdnp.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlY2l4cG9vcXFoaWZ2bXBjZG5wIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NzMzNjQ4OSwiZXhwIjoyMDYyOTEyNDg5fQ.Jc70iM3MLimK_pa53_1PMaXEYdMimVnpWLJNMynBUeU';

async function executeSQL(sql) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ query: sql });
    
    const options = {
      hostname: 'eecixpooqqhifvmpcdnp.supabase.co',
      port: 443,
      path: '/rest/v1/rpc/exec_sql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SERVICE_KEY}`,
        'apikey': SERVICE_KEY,
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ success: true, data: responseData });
        } else {
          resolve({ success: false, error: responseData, status: res.statusCode });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

async function createMissingTables() {
  console.log('🚀 Creating missing database tables...\n');

  const tables = [
    {
      name: 'user_profiles',
      sql: `
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
        
        CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
        CREATE INDEX IF NOT EXISTS idx_user_profiles_type ON user_profiles(user_type);
        ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'campaigns',
      sql: `
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
        
        CREATE INDEX IF NOT EXISTS idx_campaigns_business_id ON campaigns(business_id);
        CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);
        ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'campaign_applications',
      sql: `
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
        
        CREATE INDEX IF NOT EXISTS idx_campaign_applications_campaign_id ON campaign_applications(campaign_id);
        CREATE INDEX IF NOT EXISTS idx_campaign_applications_influencer_id ON campaign_applications(influencer_id);
        ALTER TABLE campaign_applications ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'campaign_invites',
      sql: `
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
        
        ALTER TABLE campaign_invites ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'accepted_campaigns',
      sql: `
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
        
        ALTER TABLE accepted_campaigns ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'campaign_referral_codes',
      sql: `
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
        
        ALTER TABLE campaign_referral_codes ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'visits',
      sql: `
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
        
        CREATE INDEX IF NOT EXISTS idx_visits_business_id ON visits(business_id);
        CREATE INDEX IF NOT EXISTS idx_visits_customer_id ON visits(customer_id);
        ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'content_submissions',
      sql: `
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
        
        CREATE INDEX IF NOT EXISTS idx_content_submissions_campaign_id ON content_submissions(campaign_id);
        ALTER TABLE content_submissions ENABLE ROW LEVEL SECURITY;
      `
    },
    {
      name: 'uploaded_files',
      sql: `
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
        
        CREATE INDEX IF NOT EXISTS idx_uploaded_files_user_id ON uploaded_files(user_id);
        ALTER TABLE uploaded_files ENABLE ROW LEVEL SECURITY;
      `
    }
  ];

  let successCount = 0;
  let failureCount = 0;

  for (const table of tables) {
    try {
      console.log(`📝 Creating table: ${table.name}...`);
      
      const result = await executeSQL(table.sql);
      
      if (result.success) {
        console.log(`✅ Table ${table.name} created successfully`);
        successCount++;
      } else {
        console.log(`❌ Failed to create table ${table.name}:`, result.error);
        failureCount++;
      }
      
      // Small delay between requests
      await new Promise(resolve => setTimeout(resolve, 500));
      
    } catch (err) {
      console.error(`❌ Error creating table ${table.name}:`, err.message);
      failureCount++;
    }
  }

  console.log(`\n📊 Results: ${successCount} successful, ${failureCount} failed`);
  
  if (successCount > 0) {
    console.log('\n🎉 Database tables created successfully!');
    console.log('\n🔍 Running verification...');
    
    // Run the verification script
    const { createClient } = require('@supabase/supabase-js');
    const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
    
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
          console.log(`❌ Table ${tableName} not accessible`);
        }
      } catch (err) {
        console.log(`❌ Table ${tableName} verification error`);
      }
    }
    
    console.log(`\n📋 Final Status: ${verifiedCount}/10 tables verified`);
    
    if (verifiedCount >= 8) {
      console.log('\n🎉 Database setup completed successfully!');
      console.log('🚀 Your Collabuu backend is now ready for use!');
    } else {
      console.log('\n⚠️  Some tables may still need manual creation.');
    }
  }
}

createMissingTables().catch(console.error); 