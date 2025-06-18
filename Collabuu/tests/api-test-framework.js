const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

// Test configuration
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3001';
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://eecixpooqqhifvmpcdnp.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlY2l4cG9vcXFoaWZ2bXBjZG5wIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NzMzNjQ4OSwiZXhwIjoyMDYyOTEyNDg5fQ.Jc70iM3MLimK_pa53_1PMaXEYdMimVnpWLJNMynBUeU';

// Initialize Supabase client for database verification
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// Test state management
let testTokens = {
  business: null,
  influencer: null,
  customer: null
};

let testData = {
  businessId: null,
  influencerId: null,
  customerId: null,
  campaignId: null,
  conversationId: null
};

// Utility functions
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(endpoint, method, status) {
  const statusColor = status === 'PASS' ? 'green' : status === 'FAIL' ? 'red' : 'yellow';
  log(`${method.padEnd(6)} ${endpoint.padEnd(50)} [${status}]`, statusColor);
}

function logSection(title) {
  log(`\n${'='.repeat(60)}`, 'blue');
  log(`${title}`, 'bold');
  log(`${'='.repeat(60)}`, 'blue');
}

// Database verification helpers
async function verifyDatabaseRecord(table, conditions, expectedData = null) {
  try {
    let query = supabase.from(table).select('*');
    
    // Apply conditions
    Object.entries(conditions).forEach(([key, value]) => {
      query = query.eq(key, value);
    });
    
    const { data, error } = await query;
    
    if (error) {
      log(`Database verification error: ${error.message}`, 'red');
      return false;
    }
    
    if (!data || data.length === 0) {
      log(`No records found in ${table} with conditions: ${JSON.stringify(conditions)}`, 'yellow');
      return false;
    }
    
    // If expectedData provided, verify specific fields
    if (expectedData) {
      const record = data[0];
      for (const [key, expectedValue] of Object.entries(expectedData)) {
        if (record[key] !== expectedValue) {
          log(`Database verification failed: ${key} expected ${expectedValue}, got ${record[key]}`, 'red');
          return false;
        }
      }
    }
    
    log(`✓ Database verification passed for ${table}`, 'green');
    return data[0];
  } catch (err) {
    log(`Database verification error: ${err.message}`, 'red');
    return false;
  }
}

// API test helper
async function testEndpoint(method, endpoint, data = null, token = null, expectedStatus = 200) {
  try {
    const config = {
      method,
      url: `${API_BASE_URL}${endpoint}`,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` })
      },
      ...(data && { data })
    };
    
    const response = await axios(config);
    
    if (response.status === expectedStatus) {
      logTest(endpoint, method, 'PASS');
      return { success: true, data: response.data, status: response.status };
    } else {
      logTest(endpoint, method, 'FAIL');
      log(`Expected status ${expectedStatus}, got ${response.status}`, 'red');
      return { success: false, error: `Status mismatch`, status: response.status };
    }
  } catch (error) {
    if (error.response && error.response.status === expectedStatus) {
      logTest(endpoint, method, 'PASS');
      return { success: true, data: error.response.data, status: error.response.status };
    }
    
    logTest(endpoint, method, 'FAIL');
    log(`Error: ${error.message}`, 'red');
    if (error.response) {
      log(`Response: ${JSON.stringify(error.response.data)}`, 'red');
    }
    return { success: false, error: error.message };
  }
}

// Test suites
async function testBusinessAuthentication() {
  logSection('BUSINESS AUTHENTICATION TESTS');
  
  // Test business registration
  const registerData = {
    email: `testbusiness${Date.now()}@gmail.com`,
    password: 'TestPassword123!',
    businessName: 'Test Business',
    category: 'Restaurant'
  };
  
  const registerResult = await testEndpoint('POST', '/api/business/auth/register', registerData, null, 201);
  if (!registerResult.success) return false;
  
  // Verify user was created in database
  const userRecord = await verifyDatabaseRecord('user_profiles', { 
    email: registerData.email 
  }, { 
    user_type: 'business' 
  });
  if (!userRecord) return false;
  
  testData.businessId = userRecord.id;
  
  // Verify business profile was created
  const businessRecord = await verifyDatabaseRecord('business_profiles', { 
    user_id: userRecord.id 
  }, { 
    business_name: registerData.businessName 
  });
  if (!businessRecord) return false;
  
  // Test business login
  const loginData = {
    email: registerData.email,
    password: registerData.password
  };
  
  const loginResult = await testEndpoint('POST', '/api/business/auth/login', loginData);
  if (!loginResult.success) return false;
  
  testTokens.business = loginResult.data.token;
  
  // Test get profile
  const profileResult = await testEndpoint('GET', '/api/business/profile', null, testTokens.business);
  if (!profileResult.success) return false;
  
  // Test update profile
  const updateData = {
    description: 'Updated test business description',
    website: 'https://testbusiness.com'
  };
  
  const updateResult = await testEndpoint('PUT', '/api/business/profile', updateData, testTokens.business);
  if (!updateResult.success) return false;
  
  // Verify profile was updated in database
  const updatedRecord = await verifyDatabaseRecord('business_profiles', { 
    user_id: userRecord.id 
  }, { 
    description: updateData.description,
    website: updateData.website
  });
  if (!updatedRecord) return false;
  
  return true;
}

async function testInfluencerAuthentication() {
  logSection('INFLUENCER AUTHENTICATION TESTS');
  
  // Test influencer registration
  const registerData = {
    email: `testinfluencer${Date.now()}@gmail.com`,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'Influencer',
    username: `testinfluencer${Date.now()}`,
    niche: 'Food & Lifestyle'
  };
  
  const registerResult = await testEndpoint('POST', '/api/influencer/auth/register', registerData, null, 201);
  if (!registerResult.success) return false;
  
  // Verify user was created in database
  const userRecord = await verifyDatabaseRecord('user_profiles', { 
    email: registerData.email 
  }, { 
    user_type: 'influencer' 
  });
  if (!userRecord) return false;
  
  testData.influencerId = userRecord.id;
  
  // Verify influencer profile was created
  const influencerRecord = await verifyDatabaseRecord('influencer_profiles', { 
    user_id: userRecord.id 
  }, { 
    username: registerData.username 
  });
  if (!influencerRecord) return false;
  
  // Test influencer login
  const loginData = {
    email: registerData.email,
    password: registerData.password
  };
  
  const loginResult = await testEndpoint('POST', '/api/influencer/auth/login', loginData);
  if (!loginResult.success) return false;
  
  testTokens.influencer = loginResult.data.token;
  
  return true;
}

async function testCustomerAuthentication() {
  logSection('CUSTOMER AUTHENTICATION TESTS');
  
  // Test customer registration
  const registerData = {
    email: `testcustomer${Date.now()}@gmail.com`,
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'Customer'
  };
  
  const registerResult = await testEndpoint('POST', '/api/customer/auth/register', registerData, null, 201);
  if (!registerResult.success) return false;
  
  // Verify user was created in database
  const userRecord = await verifyDatabaseRecord('user_profiles', { 
    email: registerData.email 
  }, { 
    user_type: 'customer' 
  });
  if (!userRecord) return false;
  
  testData.customerId = userRecord.id;
  
  // Verify customer profile was created
  const customerRecord = await verifyDatabaseRecord('customer_profiles', { 
    user_id: userRecord.id 
  }, { 
    first_name: registerData.firstName 
  });
  if (!customerRecord) return false;
  
  // Test customer login
  const loginData = {
    email: registerData.email,
    password: registerData.password
  };
  
  const loginResult = await testEndpoint('POST', '/api/customer/auth/login', loginData);
  if (!loginResult.success) return false;
  
  testTokens.customer = loginResult.data.token;
  
  return true;
}

async function testCampaignManagement() {
  logSection('CAMPAIGN MANAGEMENT TESTS');
  
  // Test create campaign
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
  
  const createResult = await testEndpoint('POST', '/api/business/campaigns', campaignData, testTokens.business, 201);
  if (!createResult.success) return false;
  
  testData.campaignId = createResult.data.id;
  
  // Verify campaign was created in database
  const campaignRecord = await verifyDatabaseRecord('campaigns', { 
    id: testData.campaignId 
  }, { 
    title: campaignData.title,
    business_id: testData.businessId
  });
  if (!campaignRecord) return false;
  
  // Test get campaigns
  const getCampaignsResult = await testEndpoint('GET', '/api/business/campaigns', null, testTokens.business);
  if (!getCampaignsResult.success) return false;
  
  // Test get specific campaign
  const getCampaignResult = await testEndpoint('GET', `/api/business/campaigns/${testData.campaignId}`, null, testTokens.business);
  if (!getCampaignResult.success) return false;
  
  // Test update campaign
  const updateData = {
    description: 'Updated campaign description'
  };
  
  const updateResult = await testEndpoint('PUT', `/api/business/campaigns/${testData.campaignId}`, updateData, testTokens.business);
  if (!updateResult.success) return false;
  
  // Verify campaign was updated in database
  const updatedRecord = await verifyDatabaseRecord('campaigns', { 
    id: testData.campaignId 
  }, { 
    description: updateData.description
  });
  if (!updatedRecord) return false;
  
  return true;
}

async function testInfluencerOpportunities() {
  logSection('INFLUENCER OPPORTUNITIES TESTS');
  
  // Test browse opportunities
  const opportunitiesResult = await testEndpoint('GET', '/api/influencer/opportunities', null, testTokens.influencer);
  if (!opportunitiesResult.success) return false;
  
  // Test apply to campaign
  const applicationData = {
    applicationMessage: 'I would love to participate in this campaign!'
  };
  
  const applyResult = await testEndpoint('POST', `/api/influencer/opportunities/${testData.campaignId}/apply`, applicationData, testTokens.influencer, 201);
  if (!applyResult.success) return false;
  
  // Verify application was created in database
  const applicationRecord = await verifyDatabaseRecord('campaign_applications', { 
    campaign_id: testData.campaignId,
    influencer_id: testData.influencerId
  }, { 
    status: 'pending'
  });
  if (!applicationRecord) return false;
  
  // Test get influencer campaigns (should show pending application)
  const campaignsResult = await testEndpoint('GET', '/api/influencer/campaigns', null, testTokens.influencer);
  if (!campaignsResult.success) return false;
  
  return true;
}

async function testMessagingSystem() {
  logSection('MESSAGING SYSTEM TESTS');
  
  // First, business needs to accept the influencer application
  const acceptResult = await testEndpoint('POST', `/api/business/campaigns/${testData.campaignId}/applications/${testData.influencerId}/accept`, {}, testTokens.business);
  if (!acceptResult.success) return false;
  
  // Verify accepted campaign was created
  const acceptedRecord = await verifyDatabaseRecord('accepted_campaigns', { 
    campaign_id: testData.campaignId,
    influencer_id: testData.influencerId
  });
  if (!acceptedRecord) return false;
  
  // Test get conversations (should be created automatically)
  const conversationsResult = await testEndpoint('GET', '/api/business/conversations', null, testTokens.business);
  if (!conversationsResult.success) return false;
  
  // Get conversation ID from response
  if (conversationsResult.data.length > 0) {
    testData.conversationId = conversationsResult.data[0].id;
  }
  
  // Test send message from business
  const messageData = {
    content: 'Hello! Welcome to our campaign.'
  };
  
  const sendMessageResult = await testEndpoint('POST', `/api/business/conversations/${testData.conversationId}/messages`, messageData, testTokens.business, 201);
  if (!sendMessageResult.success) return false;
  
  // Verify message was created in database
  const messageRecord = await verifyDatabaseRecord('messages', { 
    conversation_id: testData.conversationId,
    sender_id: testData.businessId
  }, { 
    content: messageData.content
  });
  if (!messageRecord) return false;
  
  // Test get messages
  const getMessagesResult = await testEndpoint('GET', `/api/business/conversations/${testData.conversationId}/messages`, null, testTokens.business);
  if (!getMessagesResult.success) return false;
  
  return true;
}

async function testVisitTracking() {
  logSection('VISIT TRACKING TESTS');
  
  // Test generate QR code for customer
  const qrResult = await testEndpoint('GET', `/api/customer/favorites/${testData.campaignId}/qr-code`, null, testTokens.customer);
  if (!qrResult.success) return false;
  
  const qrCode = qrResult.data.qrCode;
  
  // Test verify visit
  const verifyData = {
    qrCode: qrCode,
    campaignId: testData.campaignId,
    influencerId: testData.influencerId,
    customerId: testData.customerId
  };
  
  const verifyResult = await testEndpoint('POST', '/api/business/visits/verify', verifyData, testTokens.business, 201);
  if (!verifyResult.success) return false;
  
  // Verify visit was created in database
  const visitRecord = await verifyDatabaseRecord('visits', { 
    campaign_id: testData.campaignId,
    customer_id: testData.customerId,
    influencer_id: testData.influencerId
  }, { 
    status: 'pending'
  });
  if (!visitRecord) return false;
  
  // Test approve visit
  const approveResult = await testEndpoint('POST', `/api/business/visits/${visitRecord.id}/approve`, {}, testTokens.business);
  if (!approveResult.success) return false;
  
  // Verify visit was approved in database
  const approvedRecord = await verifyDatabaseRecord('visits', { 
    id: visitRecord.id
  }, { 
    status: 'verified'
  });
  if (!approvedRecord) return false;
  
  return true;
}

async function testLoyaltySystem() {
  logSection('LOYALTY SYSTEM TESTS');
  
  // Test get customer loyalty points
  const loyaltyResult = await testEndpoint('GET', '/api/customer/rewards', null, testTokens.customer);
  if (!loyaltyResult.success) return false;
  
  // Test get available rewards
  const rewardsResult = await testEndpoint('GET', '/api/customer/rewards/available', null, testTokens.customer);
  if (!rewardsResult.success) return false;
  
  // Test loyalty points transaction history
  const historyResult = await testEndpoint('GET', '/api/customer/rewards/history', null, testTokens.customer);
  if (!historyResult.success) return false;
  
  return true;
}

// Main test runner
async function runAllTests() {
  log('🚀 Starting Collabuu API Test Suite', 'bold');
  log(`Testing against: ${API_BASE_URL}`, 'blue');
  
  const testSuites = [
    { name: 'Business Authentication', fn: testBusinessAuthentication },
    { name: 'Influencer Authentication', fn: testInfluencerAuthentication },
    { name: 'Customer Authentication', fn: testCustomerAuthentication },
    { name: 'Campaign Management', fn: testCampaignManagement },
    { name: 'Influencer Opportunities', fn: testInfluencerOpportunities },
    { name: 'Messaging System', fn: testMessagingSystem },
    { name: 'Visit Tracking', fn: testVisitTracking },
    { name: 'Loyalty System', fn: testLoyaltySystem }
  ];
  
  let passedSuites = 0;
  let totalSuites = testSuites.length;
  
  for (const suite of testSuites) {
    try {
      const result = await suite.fn();
      if (result) {
        log(`✓ ${suite.name} - PASSED`, 'green');
        passedSuites++;
      } else {
        log(`✗ ${suite.name} - FAILED`, 'red');
      }
    } catch (error) {
      log(`✗ ${suite.name} - ERROR: ${error.message}`, 'red');
    }
  }
  
  logSection('TEST SUMMARY');
  log(`Total Test Suites: ${totalSuites}`, 'blue');
  log(`Passed: ${passedSuites}`, 'green');
  log(`Failed: ${totalSuites - passedSuites}`, 'red');
  log(`Success Rate: ${((passedSuites / totalSuites) * 100).toFixed(1)}%`, 'bold');
  
  if (passedSuites === totalSuites) {
    log('\n🎉 ALL TESTS PASSED! API is working correctly.', 'green');
  } else {
    log('\n❌ Some tests failed. Please check the logs above.', 'red');
  }
}

// Export for use in other test files
module.exports = {
  testEndpoint,
  verifyDatabaseRecord,
  runAllTests,
  testTokens,
  testData
};

// Run tests if this file is executed directly
if (require.main === module) {
  runAllTests().catch(console.error);
} 