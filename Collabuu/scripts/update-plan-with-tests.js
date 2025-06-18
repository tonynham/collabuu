const fs = require('fs');
const path = require('path');

// Read the plan file
const planPath = path.join(__dirname, '../.code/plan.md');
let planContent = fs.readFileSync(planPath, 'utf8');

// Regular expression to match endpoint lines that have [x] implementation but no api_test
const endpointRegex = /^(\s*- \[x\] `[^`]+` - [^[]+\[x\] implementation)(?!\s*\[\s*\]\s*api_test)(.*)$/gm;

// Replace function to add [ ] api_test to each endpoint
const updatedContent = planContent.replace(endpointRegex, '$1 [ ] api_test$2');

// Write the updated content back to the file
fs.writeFileSync(planPath, updatedContent, 'utf8');

console.log('✅ Successfully updated plan.md with api_test markers for all endpoints');

// Count how many endpoints were updated
const matches = planContent.match(endpointRegex);
const totalEndpoints = matches ? matches.length : 0;

console.log(`📊 Added api_test markers to ${totalEndpoints} endpoints`);

// Show a sample of what was changed
if (matches && matches.length > 0) {
  console.log('\n📝 Sample changes:');
  matches.slice(0, 3).forEach((match, index) => {
    const updated = match.replace(endpointRegex, '$1 [ ] api_test$2');
    console.log(`${index + 1}. ${updated.trim()}`);
  });
  
  if (matches.length > 3) {
    console.log(`   ... and ${matches.length - 3} more endpoints`);
  }
} 