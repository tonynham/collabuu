const { testEndpoint, verifyDatabaseRecord } = require('./api-test-framework');

// Configuration
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001';

// Test specific endpoints
async function testHealthEndpoint() {
  console.log('🔍 Testing Health Endpoint...');
  
  const result = await testEndpoint('GET', '/health');
  if (result.success) {
    console.log('✅ Health endpoint is working');
    console.log('Response:', result.data);
  } else {
    console.log('❌ Health endpoint failed');
  }
  
  return result.success;
}

async function testCategoriesEndpoint() {
  console.log('🔍 Testing Categories Endpoint...');
  
  const result = await testEndpoint('GET', '/api/categories');
  if (result.success) {
    console.log('✅ Categories endpoint is working');
    console.log(`Found ${result.data.length} categories`);
  } else {
    console.log('❌ Categories endpoint failed');
  }
  
  return result.success;
}

async function testBusinessRegistration() {
  console.log('🔍 Testing Business Registration...');
  
  const registerData = {
    email: `testbusiness${Date.now()}@gmail.com`,
    password: 'TestPassword123!',
    businessName: 'Test Business',
    category: 'Restaurant'
  };
  
  const result = await testEndpoint('POST', '/api/business/auth/register', registerData, null, 201);
  if (result.success) {
    console.log('✅ Business registration is working');
    
    // Verify in database
    const userRecord = await verifyDatabaseRecord('user_profiles', { 
      email: registerData.email 
    }, { 
      user_type: 'business' 
    });
    
    if (userRecord) {
      console.log('✅ Database verification passed');
      return { success: true, userId: userRecord.id, token: result.data.token };
    } else {
      console.log('❌ Database verification failed');
      return { success: false };
    }
  } else {
    console.log('❌ Business registration failed');
    return { success: false };
  }
}

async function testInfluencerRegistration() {
  console.log('🔍 Testing Influencer Registration...');
  
  const registerData = {
    email: `testinfluencer${Date.now()}@gmail.com`,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'Influencer',
    username: `testinfluencer${Date.now()}`,
    niche: 'Food & Lifestyle'
  };
  
  const result = await testEndpoint('POST', '/api/influencer/auth/register', registerData, null, 201);
  if (result.success) {
    console.log('✅ Influencer registration is working');
    
    // Verify in database
    const userRecord = await verifyDatabaseRecord('user_profiles', { 
      email: registerData.email 
    }, { 
      user_type: 'influencer' 
    });
    
    if (userRecord) {
      console.log('✅ Database verification passed');
      return { success: true, userId: userRecord.id, token: result.data.token };
    } else {
      console.log('❌ Database verification failed');
      return { success: false };
    }
  } else {
    console.log('❌ Influencer registration failed');
    return { success: false };
  }
}

async function testCustomerRegistration() {
  console.log('🔍 Testing Customer Registration...');
  
  const registerData = {
    email: `testcustomer${Date.now()}@gmail.com`,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'Customer'
  };
  
  const result = await testEndpoint('POST', '/api/customer/auth/register', registerData, null, 201);
  if (result.success) {
    console.log('✅ Customer registration is working');
    
    // Verify in database
    const userRecord = await verifyDatabaseRecord('user_profiles', { 
      email: registerData.email 
    }, { 
      user_type: 'customer' 
    });
    
    if (userRecord) {
      console.log('✅ Database verification passed');
      return { success: true, userId: userRecord.id, token: result.data.token };
    } else {
      console.log('❌ Database verification failed');
      return { success: false };
    }
  } else {
    console.log('❌ Customer registration failed');
    return { success: false };
  }
}

async function testCampaignCreation(businessToken, businessId) {
  console.log('🔍 Testing Campaign Creation...');
  
  const campaignData = {
    title: 'Test Campaign',
    description: 'Test campaign description',
    campaignType: 'pay_per_customer',
    visibility: 'public',
    requirements: 'Test requirements',
    targetCustomers: 100,
    influencerSpots: 10,
    periodStart: new Date().toISOString(),
    periodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    creditsPerAction: 10,
    totalCredits: 1000
  };
  
  const result = await testEndpoint('POST', '/api/business/campaigns', campaignData, businessToken, 201);
  if (result.success) {
    console.log('✅ Campaign creation is working');
    
    // Verify in database
    const campaignRecord = await verifyDatabaseRecord('campaigns', { 
      id: result.data.id 
    }, { 
      title: campaignData.title,
      business_id: businessId
    });
    
    if (campaignRecord) {
      console.log('✅ Database verification passed');
      return { success: true, campaignId: result.data.id };
    } else {
      console.log('❌ Database verification failed');
      return { success: false };
    }
  } else {
    console.log('❌ Campaign creation failed');
    return { success: false };
  }
}

// Main test runner for specific endpoints
async function runSpecificTests() {
  console.log('🚀 Running Specific Endpoint Tests\n');
  
  const tests = [
    { name: 'Health Check', fn: testHealthEndpoint },
    { name: 'Categories', fn: testCategoriesEndpoint }
  ];
  
  let passedTests = 0;
  
  for (const test of tests) {
    try {
      const result = await test.fn();
      if (result) {
        console.log(`✅ ${test.name} - PASSED\n`);
        passedTests++;
      } else {
        console.log(`❌ ${test.name} - FAILED\n`);
      }
    } catch (error) {
      console.log(`❌ ${test.name} - ERROR: ${error.message}\n`);
    }
  }
  
  // Test user registration flow
  console.log('🔍 Testing User Registration Flow...\n');
  
  const businessResult = await testBusinessRegistration();
  const influencerResult = await testInfluencerRegistration();
  const customerResult = await testCustomerRegistration();
  
  if (businessResult.success) {
    passedTests++;
    console.log('✅ Business Registration - PASSED\n');
    
    // Test campaign creation with the business token
    const campaignResult = await testCampaignCreation(businessResult.token, businessResult.userId);
    if (campaignResult.success) {
      passedTests++;
      console.log('✅ Campaign Creation - PASSED\n');
    } else {
      console.log('❌ Campaign Creation - FAILED\n');
    }
  } else {
    console.log('❌ Business Registration - FAILED\n');
  }
  
  if (influencerResult.success) {
    passedTests++;
    console.log('✅ Influencer Registration - PASSED\n');
  } else {
    console.log('❌ Influencer Registration - FAILED\n');
  }
  
  if (customerResult.success) {
    passedTests++;
    console.log('✅ Customer Registration - PASSED\n');
  } else {
    console.log('❌ Customer Registration - FAILED\n');
  }
  
  const totalTests = tests.length + 4; // 2 basic tests + 3 registration tests + 1 campaign test
  
  console.log('📊 Test Summary:');
  console.log(`Total Tests: ${totalTests}`);
  console.log(`Passed: ${passedTests}`);
  console.log(`Failed: ${totalTests - passedTests}`);
  console.log(`Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
  
  if (passedTests === totalTests) {
    console.log('\n🎉 ALL SPECIFIC TESTS PASSED!');
  } else {
    console.log('\n⚠️  Some tests failed. Check the logs above.');
  }
}

// Command line argument handling
const args = process.argv.slice(2);

if (args.length > 0) {
  const testName = args[0].toLowerCase();
  
  switch (testName) {
    case 'health':
      testHealthEndpoint();
      break;
    case 'categories':
      testCategoriesEndpoint();
      break;
    case 'business':
      testBusinessRegistration();
      break;
    case 'influencer':
      testInfluencerRegistration();
      break;
    case 'customer':
      testCustomerRegistration();
      break;
    default:
      console.log('Available tests: health, categories, business, influencer, customer');
      console.log('Or run without arguments to run all specific tests');
  }
} else {
  runSpecificTests().catch(console.error);
}

module.exports = {
  testHealthEndpoint,
  testCategoriesEndpoint,
  testBusinessRegistration,
  testInfluencerRegistration,
  testCustomerRegistration,
  testCampaignCreation
}; 